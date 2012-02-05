require 'spec_helper'

describe AuthenticationController do
  def mock_person(stubs={})
    @mock_person ||= mock_model(Person, stubs).as_null_object
  end
  
  context "before_filters" do
    it "should skip require_no_ssl filter " do
      controller.should_not_receive(:require_no_ssl)
      get :decline_fb_auth
    end
  end

  context "POST decline_fb_auth" do

    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end

    it "should set declined_fb_auth to true" do
      @person.should_receive(:update_attribute).with(:declined_fb_auth, true).and_return(true)
      post :decline_fb_auth
      response.should be_ok
    end

    it "should return different status if unable to set declined_fb_auth to true" do
      @person.should_receive(:update_attribute).with(:declined_fb_auth, true).and_return(false)
      @controller.stub_chain(:current_person,:errors,:full_messages).and_return('error messages here')
      post :decline_fb_auth
      response.body.should contain('error messages here')
      response.status.should == 422
    end

  end

  context "GET conflicting_email" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end

    it "should render no layout" do
      get :conflicting_email
      response.should render_template(:layout => false)
    end
  end

  context "PUT update_conflicting_email" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end

    it "should update current person's email if session[:other_email] is not blank" do
      session[:other_email] = 'johnd@test.com'
      @person.should_receive(:update_attribute).with(:email, 'johnd@test.com').and_return(true)
      put :update_conflicting_email
      response.should be_ok
    end
    
    it "should clear the session[:other_email]" do
      session[:other_email] = 'johnd@test.com'
      put :update_conflicting_email
      session[:other_email].should be_nil
    end
    
    it "should not update current person's email if session[:other_email] is blank" do
      @person.should_not_receive(:update_attribute)
      put :update_conflicting_email
      response.status.should == 422
    end
  end

  context "GET registering_email_taken" do
    it "should render no layout" do
      get :registering_email_taken
      response.should render_template(:layout => false)
    end
  end

  context "GET conflicting_email" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end
    
    it "should render no layout" do
      get :conflicting_email
      response.should render_template(:layout => false)
    end
  end
  
  context "GET successful_registration" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end
    
    it "should render no layout" do
      get :successful_registration
      response.should render_template(:layout => false)
    end
  end


  context "GET fb_linking_success" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end
    
    it "should render no layout" do
      get :fb_linking_success
      response.should render_template(:layout => false)
    end
  end

  context "GET confirm_facebook_unlinking" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end

    context "XHR" do
      it "should render the layout for XHR request" do
        xhr :get, :confirm_facebook_unlinking
        response.should render_template('layouts/content_for/main_body')
      end
    end

    context "not XHR" do
      it "should render regular layout" do
        get :confirm_facebook_unlinking
        response.should render_template('layouts/application')
      end
    end
  end
  
  context "GET before_facebook_unlinking" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end
    
    it "should have person" do
      get :before_facebook_unlinking
      assigns(:person).should == @person
    end
  end
  
  context "DELETE process_facebook_unlinking" do
    before(:each) do
      @person = mock_person
      @controller.stub(:current_person).and_return(@person)
    end
    
    it "should unlink with facebook" do
      @person.should_receive(:unlink_from_facebook)
      delete :process_facebook_unlinking
    end
    
    it "should render the template /authentication/fb_unlinking_success when successful" do
      @person.stub(:valid?).and_return(true)
      delete :process_facebook_unlinking
      response.should render_template("authentication/fb_unlinking_success", "layouts/application")
    end
    
    it "should re-sign-in using Devise(i.e. not log out automatically)" do
      @person.stub(:valid?).and_return(true)
      controller.should_receive(:sign_in).with(@person,hash_including(:event => :authentication, :bypass => true))
      delete :process_facebook_unlinking
    end
    
    it "should render the template /authentication/before_facebook_unlinking if there is validation error" do
      @person.stub(:valid?).and_return(false)
      delete :process_facebook_unlinking
      response.should render_template("authentication/before_facebook_unlinking", "layouts/application")
    end
    
  end
end
