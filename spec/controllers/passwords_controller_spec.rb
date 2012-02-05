require 'spec_helper'

describe PasswordsController do
  def mock_person(stubs={})
    @mock_person ||= mock_model(Person, stubs).as_null_object
  end
  
  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:person]
  end
  
  context "before_filters" do
    before(:each) do
      @person = mock_person
      @person.stub(:facebook_authenticated?).and_return(true)
      controller.stub(:resource_class, :send_reset_password_instructions).and_return(@person)
    end
    it "should skip require_no_ssl filter " do
      controller.should_not_receive(:require_no_ssl)
      post :create
    end
  end
  
  context "POST create" do
    context "facebook authenticated" do
      before(:each) do
        @person = mock_person
        @person.stub(:facebook_authenticated?).and_return(true)
        controller.stub(:resource_class, :send_reset_password_instructions).and_return(@person)
      end
      
      it "should render new" do
        post :create
        response.should render_template('new')
      end
      
      it "should set @fb_auth_forgot_password to true for colorbox in the view" do
        post :create
        assigns(:fb_auth_forgot_password).should be_true
      end
    end
    context "when having no errors" do
      before(:each) do
        @person = mock_person
        @person.stub(:facebook_authenticated?).and_return(false)
        controller.stub(:resource_class, :send_reset_password_instructions).and_return(@person)
      end
      
      it "should redirect_to person_new_sessions_path" do
        post :create
        response.should redirect_to new_person_session_path
      end
      
      it "should set flash message" do
        controller.should_receive(:set_flash_message).with(:notice, :send_instructions)
        post :create
      end
    end
    context "when having other errors" do
      before(:each) do
        @person = mock_person
        @person.stub(:facebook_authenticated?).and_return(false)
        @person.stub_chain(:errors,:empty?).and_return(false)
        controller.stub(:resource_class, :send_reset_password_instructions).and_return(@person)
      end

      it "should render new" do
        post :create
        response.should render_template('new')
      end
    end
  end
  
  context "GET fb_auth_forgot_password" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end
    
    it "should render no layout" do
      get :fb_auth_forgot_password
      response.should render_template(:layout => false)
    end
  end
  
end
