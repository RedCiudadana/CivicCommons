require 'spec_helper'
include ControllerMacros

describe ReflectionsController do

  def mock_conversation(stubs={})
    @mock_conversation ||= mock_model(Conversation, stubs).as_null_object
  end

  def mock_reflection(stubs={})
    @mock_reflection ||= mock_model(Reflection, stubs).as_null_object
  end

  def stub_person(stubs={:id => 111})
    @stub_person ||= stub_model(Person, stubs).as_null_object
  end

  before(:each) do
    @controller.stub!(:require_user).and_return(true)
    @controller.stub!(:current_person).and_return(stub_person)
    Conversation.stub(:find).with(7) { mock_conversation }
  end

  describe "GET index" do
    it "assigns all reflections as @reflections" do
      Reflection.stub(:where) { mock_reflection }
      mock_reflection.stub(:order) {[mock_reflection]}
      get :index, :controller => "reflections", :conversation_id => 7
      assigns(:conversation).should eq(mock_conversation)
      assigns(:reflections).should eq([mock_reflection])
    end
  end

  describe "GET show" do
    it "assigns the requested reflection as @reflection" do
      Reflection.stub(:find).with("37", {:include=>:person}) { mock_reflection }
      get :show, :id => "37", :conversation_id => 7
      assigns(:reflection).should be(mock_reflection)
      assigns(:participated_actions).should be(mock_reflection)
    end
    it "should initiate a new comment" do
      comment_double = double('Comment')
      Reflection.stub(:find).with("37", {:include=>:person}) { mock_reflection(:comments => comment_double) }
      comment_double.should_receive(:new)
      get :show, :id => "37", :conversation_id => 7
    end
    it "should fetch comments" do
      comment_double = double('Comment')
      Reflection.stub(:find).with("37", {:include=>:person}) { mock_reflection(:comments => comment_double) }
      comment_double.stub(:new)
      get :show, :id => "37", :conversation_id => 7
      assigns(:comments).should be(comment_double)
    end
  end

  describe "GET new" do
    it "assigns a new reflection as @reflection" do
      Reflection.stub(:new) { mock_reflection }
      get :new, :conversation_id => 7
      assigns(:conversation).should == mock_conversation
      assigns(:reflection).should be(mock_reflection)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created reflection as @reflection" do
        Reflection.stub(:new).with({'these' => 'params'}) { mock_reflection(:save => true) }
        post :create, :reflection => {'these' => 'params'}, :conversation_id => 7
        assigns(:reflection).should be(mock_reflection)
      end

      it "redirects to the created reflection" do
        Reflection.stub(:new) { mock_reflection(:save => true) }
        post :create, :reflection => {}, :conversation_id => 7
        response.should redirect_to(conversation_reflection_path(mock_conversation, mock_reflection))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved reflection as @reflection" do
        Reflection.stub(:new).with({'these' => 'params'}) { mock_reflection(:save => false) }
        post :create, :reflection => {'these' => 'params'}, :conversation_id => 7
        assigns(:reflection).should be(mock_reflection)
      end

      it "re-renders the 'new' template" do
        Reflection.stub(:new) { mock_reflection(:save => false) }
        post :create, :reflection => {}, :conversation_id => 7
        response.should render_template("new")
      end
    end
  end
end

describe ReflectionsController do
  describe "PUT update" do
    context "as admin" do
      before(:each) do
        login_admin
        @reflection = FactoryGirl.create(:reflection)
      end

      describe "with valid params" do
        it "updates the requested reflection" do
          put :update, :id => @reflection.id, :reflection => { 'title' => 'new title!' }, :conversation_id => @reflection.conversation_id
          @reflection.reload.title.should == 'new title!'
        end

        it "assigns the requested reflection as @reflection" do
          put :update, :id => @reflection.id, :reflection => {}, :conversation_id => @reflection.conversation_id
          assigns[:reflection].id.should == @reflection.id
        end

        it "redirects to the reflection" do
          put :update, :id => @reflection.id, :reflection => {}, :conversation_id => @reflection.conversation_id
          response.should redirect_to(conversation_reflection_path(@reflection.conversation, @reflection))
        end
      end

      describe "with invalid params" do
        it "assigns the reflection as @reflection" do
          put :update, :id => @reflection.id, :reflection => { 'invalid' => 'attribute' }, :conversation_id => @reflection.conversation_id
          assigns[:reflection].id.should == @reflection.id
        end
      end
    end

    context "as non-admin but logged in" do
      before(:each) do
        login_user
        @reflection = FactoryGirl.create(:reflection)
      end

      it "sets flash[:error]" do
        put :update, :id => @reflection.id, :reflection => {}, :conversation_id => @reflection.conversation_id
        flash[:error].should == "You must be an admin to view this page."
      end

      it "redirects to profile page" do
        put :update, :id => @reflection.id, :reflection => {}, :conversation_id => @reflection.conversation_id
        response.should redirect_to(@controller.secure_session_url(@controller.current_person))
      end
    end

    context "not logged in" do
      before(:each) do
        login_user
        @reflection = FactoryGirl.create(:reflection)
      end

      it "redirects to login page" do
        put :update, :id => @reflection.id, :reflection => {}, :conversation_id => @reflection.conversation_id
        response.should redirect_to(@controller.secure_new_person_session_url)
      end
    end
  end

  describe "GET edit" do
    context "as admin" do
      before(:each) do
        login_admin
        @reflection = FactoryGirl.create(:reflection)
      end

      it "assigns the requested reflection as @reflection" do
        get :edit, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        assigns[:reflection].id.should == @reflection.id
      end
    end

    context "as non-admin but logged in" do
      before(:each) do
        login_user
        @reflection = FactoryGirl.create(:reflection)
      end

      it "sets flash[:error]" do
        get :edit, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        flash[:error].should == "You must be an admin to view this page."
      end

      it "redirects to profile page" do
        get :edit, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        response.should redirect_to(@controller.secure_session_url(@controller.current_person))
      end
    end

    context "not logged in" do
      before(:each) do
        login_user
        @reflection = FactoryGirl.create(:reflection)
      end

      it "redirects to login page" do
        get :edit, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        response.should redirect_to(@controller.secure_new_person_session_url)
      end
    end
  end

  describe "DELETE destroy" do
    context "as admin" do
      before(:each) do
        login_admin
        @reflection = FactoryGirl.create(:reflection)
      end

      it "assigns the requested reflection as @reflection" do
        delete :destroy, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        assigns[:reflection].id.should == @reflection.id
      end

      it "redirects to conversation_reflection_path" do
        delete :destroy, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        response.should redirect_to(conversation_reflections_path(@reflection.conversation))
      end
    end

    context "as non-admin but logged in" do
      before(:each) do
        login_user
        @reflection = FactoryGirl.create(:reflection)
      end

      it "sets flash[:error]" do
        delete :destroy, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        flash[:error].should == "You must be an admin to view this page."
      end

      it "redirects to profile page" do
        delete :destroy, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        response.should redirect_to(@controller.secure_session_url(@controller.current_person))
      end
    end

    context "not logged in" do
      before(:each) do
        login_user
        @reflection = FactoryGirl.create(:reflection)
      end

      it "redirects to login page" do
        delete :destroy, :id => @reflection.id, :conversation_id => @reflection.conversation_id
        response.should redirect_to(@controller.secure_new_person_session_url)
      end
    end
  end
end
