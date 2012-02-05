require 'spec_helper'
require 'devise/test_helpers'

describe SessionsController do
  
  def mock_person(stubs={})
    @mock_person ||= mock_model(Person, stubs).as_null_object
  end

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:person]
  end
  
  context "before_filters" do
    it "should skip require_no_ssl filter " do
      controller.should_not_receive(:require_no_ssl)
      get :new
    end
  end
  
  
  context "POST create" do
    
    context "redirection after signing in" do
      
      before(:each) do
        @person = Factory.create(:registered_user)
        warden.stub(:authenticate!).and_return(@person)
      end
      
      it "should redirect to the previous page, if there was a previous page" do
        session[:previous] = 'http://test.host/conversations'
        
        post :create
        response.should redirect_to 'http://test.host/conversations'
      end

      it "should redirect to root_url if previous page is 'people/login'" do
        session[:previous] = 'http://test.host/people/login'
        
        post :create
        response.should redirect_to 'http://test.host/'
      end

      it "should redirect to root_url if previous page is 'register/new'" do
        session[:previous] = 'http://test.host/people/register/new'
        
        post :create
        response.should redirect_to 'http://test.host/'
      end

      it "should redirect to root_url by default" do
        post :create
        response.should redirect_to 'http://test.host/'
      end

    end
    
  end

  context "GET ajax_new" do
    it "should set the previous session if the previous url is valid" do
      RedirectHelper.stub!(:valid?).and_return(true)
      request.stub!(:headers).and_return({'Referer' => 'http://test.com'})
      get :ajax_new
      session[:previous].should == 'http://test.com'
    end
    it "should set the close_modal_on_exit session to true" do
      get :ajax_new
      session[:close_modal_on_exit].should == true
    end
  end
  context "POST ajax_create" do
    before(:each) do
      @person = Factory.create(:registered_user)
      warden.stub(:authenticate!).and_return(@person)
    end
    describe "when close_modal_on_exit is true" do
      before(:each) do
        session[:close_modal_on_exit] = true
      end
      it "should set @notice to 'You have successfully logged in.'" do
        post :ajax_create
        assigns(:notice).should == "You have successfully logged in."
      end
      
      context ".js" do
        it "should render the close_modal_on_exit.js template" do
          post :ajax_create, :format => :js
          response.should render_template('sessions/_close_modal_on_exit')
        end
      end
      context ".html" do
        it "should redirect to previous session if it exists" do
          session[:previous] = 'http://previous'
          post :ajax_create, :format => :html
          response.should redirect_to 'http://previous'          
        end
        it "should not render the close_modal_on_exit template" do
          post :ajax_create, :format => :html
          response.should_not render_template('sessions/_close_modal_on_exit')
        end
        it "should redirect to root if previous session doesn't exist" do
          post :ajax_create, :format => :html
          response.should redirect_to root_path
        end
        it "should set the previous session to nil" do
          session[:previous] = 'http://previous'
          post :ajax_create, :format => :html
          session[:previous].should be_nil
        end
      end
    end
  end
  
end
