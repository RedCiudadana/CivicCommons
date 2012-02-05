require 'spec_helper'
require 'acceptance/support/facebookable'

describe Registrations::OmniauthCallbacksController, "handle facebook authentication callback" do
  include Facebookable
  
  def response_should_js_redirect_to(path)
    assigns(:script).should contain "window.opener.location = '#{path}'"
  end

  def response_should_js_open_colorbox(path)
    assigns(:script).should contain "window.opener.$.colorbox({href:'#{path}'"
  end

  def stub_successful_auth
    request.env["devise.mapping"] = Devise.mappings[:person]
    env = {
      "omniauth.auth" => auth_hash,
      "omniauth.origin" => conversations_path
    }
    @controller.stub!(:env).and_return(env)
  end

  def stub_failed_auth
    request.env["devise.mapping"] = Devise.mappings[:person]
    env = { "omniauth.auth" => {},
            "omniauth.origin" => conversations_path}
    @controller.stub!(:env).and_return(env)
  end


  def stub_fb_auth_w_conflicting_email
    request.env["devise.mapping"] = Devise.mappings[:person]
    hash = auth_hash
    hash['info']['email'] = "johnd-different-email@test.com"
    env = { "omniauth.auth" => hash }
    @controller.stub!(:env).and_return(env)
  end

  def stub_failed_auth
    request.env["devise.mapping"] = Devise.mappings[:person]
    env = { "omniauth.auth" => {} }
    @controller.stub!(:env).and_return(env)
  end
  
  let(:registered_user) { Factory :registered_user, email: 'johnd@test.com' }
  
  context "before_filters" do
    it "should skip require_no_ssl filter " do
      stub_successful_auth
      stub_facebook_auth_with_email_for registered_user
      sign_in registered_user
      
      controller.should_not_receive(:require_no_ssl)
      get :facebook
    end
  end

  describe "facebook" do
    def mock_authentication(stubs={})
      @mock_authentication ||= mock_model(Authentication, stubs).as_null_object
    end

    def mock_person(stubs={})
      @mock_person ||= mock_model(Person, stubs).as_null_object
    end

    context "logged in and linking account with facebook" do
      context "when successfully authenticated to facebook" do
        before(:each) do
          stub_successful_auth
          stub_facebook_auth_with_email_for registered_user
          sign_in registered_user
          get :facebook
        end

        it "should have linked the account with facebook" do
          registered_user.reload.facebook_authenticated?.should be_true
        end

        it "should display Facebook linking success modal" do
          response_should_js_open_colorbox(fb_linking_success_path)
        end

        it "should display the success message" do
          flash[:notice].should == "Successfully linked your account to Facebook"
        end

      end
    end
    context "when updating with a conflicting email address" do
      before(:each) do
        stub_fb_auth_w_conflicting_email
        sign_in registered_user
        get :facebook
      end
      it "should prompt the user to approve the email update with the new email in facebook or not" do
        response_should_js_open_colorbox(conflicting_email_path)
      end
    end
    context "when failed authenticating to facebook" do
      before(:each) do
        stub_failed_auth
        sign_in registered_user
        get :facebook
      end

      it "should not have link the account with facebook" do
        registered_user.facebook_authenticated?.should be_false
      end

      it "redirects to homepage" do
        response_should_js_redirect_to(root_path)
      end

      it "should display failed to link message" do
        flash[:notice].should == "Could not link your account to Facebook"
      end
    end
    describe "logging in using facebook" do
      let(:facebook_user) { Factory.create(:registered_user_with_facebook_authentication) }

      context "successfully" do
        before(:each) do
          stub_successful_auth
          @controller.stub(:signed_in?).and_return(false)
          Authentication.should_receive(:find_from_auth_hash).and_return(facebook_user.facebook_authentication)
          sign_in facebook_user
          get :facebook
        end

        it "redirects to the previous page" do
          response_should_js_redirect_to(conversations_path)
        end

        it "flashes successful facebook login" do
          flash[:notice].should == 'Successfully authorized from Facebook account.'
        end
      end
    end
    context "creating a new account using facebook credentials" do
      context "successfully" do
        before(:each) do
          stub_successful_auth
          @controller.stub(:signed_in?).and_return(false)
          Authentication.should_receive(:find_from_auth_hash).and_return(nil)
        end

      end
    end
  end

  describe "miscelaneous failure" do
    before(:each) do
      controller.stub_chain(:failed_strategy,:name).and_return('Facebook')
      I18n.stub(:t).and_return('error message here')
    end
    it "should display the text of the failure" do
      stub_failed_auth
      @controller.should_receive(:render_popup).with("error message here")
      @controller.stub(:render)
      get :failure
    end
  end
end
