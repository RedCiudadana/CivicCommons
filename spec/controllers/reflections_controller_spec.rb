require 'spec_helper'

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
      Reflection.stub(:where) { [mock_reflection] }
      #get :index, :controller => "reflections", :conversation_id => 7
      get :index, :controller => "reflections", :conversation_id => 7
      assigns(:conversation).should eq(mock_conversation)
      assigns(:reflections).should eq([mock_reflection])
    end
  end

  describe "GET show" do
    it "assigns the requested reflection as @reflection" do
      Reflection.stub(:find).with("37") { mock_reflection }
      get :show, :id => "37", :conversation_id => 7
      assigns(:reflection).should be(mock_reflection)
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

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested reflection" do
        Reflection.stub(:find).with("37") { mock_reflection }
        mock_reflection.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :reflection => {'these' => 'params'}, :conversation_id => 7
      end

      it "assigns the requested reflection as @reflection" do
        Reflection.stub(:find) { mock_reflection(:update_attributes => true) }
        put :update, :id => "1", :conversation_id => 7
        assigns(:reflection).should be(mock_reflection)
      end

      it "redirects to the reflection" do
        Reflection.stub(:find) { mock_reflection(:update_attributes => true) }
        put :update, :id => "1", :conversation_id => 7
        response.should redirect_to(conversation_reflection_path(mock_conversation, mock_reflection))
      end
    end

    describe "with invalid params" do
      it "assigns the reflection as @reflection" do
        Reflection.stub(:find) { mock_reflection(:update_attributes => false) }
        put :update, :id => "1", :conversation_id => 7
        assigns(:reflection).should be(mock_reflection)
      end
    end
  end

end
