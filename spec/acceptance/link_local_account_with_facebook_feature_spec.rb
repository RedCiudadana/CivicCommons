require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

feature "8457517 link local account with facebook", %q{
  In order use CivicCommons
  As an existing user with a local account
  I want to authenticate through Facebook
  So that I only have to remember one login and password
} do
  include Facebookable
  before do
    stub_facebook_auth
    sign_out
  end

  let (:forgot_password_page)       { ForgotPasswordPage.new(page) }

  def response_should_js_redirect_to(path)
    page.should contain "window.opener.location = '#{path}'"
  end

  def response_should_js_open_colorbox(path)
    page.should contain "$.colorbox({href:'#{path}'"
  end

  def suggestion_to_connect_to_facebook
    auth_modal = ".suggest-auth.facebook-auth"
    sleep 3
    if page.has_css? auth_modal
      page.find(auth_modal)
    else
      InvisibleObject.new
    end
  end
  class InvisibleObject
    def visible?
      false
    end
  end
  context "When I have not linked my account to Facebook" do
    scenario "use facebook email if conflicting", :js=>true do
      login_as :registered_user
      begin_connecting_to_facebook
      use_facebook_email
      wait_until { reload_logged_in_user.email == 'johnd@test.com' }
      logged_in_user.email.should == 'johnd@test.com'
    end

    scenario "I should be able to link my account to facebook from the 'accounts' page", :js=>true do
      login_as :registered_user, email: 'johnd@test.com'
      connect_account_to_facebook
      logged_in_user.should be_facebook_authenticated
      goto :edit_profile_page, :for => logged_in_user
      page.should_not have_link 'Connect with Facebook'
      sleep 3
      page.should have_link "Unlink from Facebook"
    end

    context "and I am an organization" do
      scenario "I should not see the modal dialog to 'link the account to facebook'", :js => true do
        login_as :newly_confirmed_organization, email: 'info@testorg.com'
        page.should_not have_link 'Connect with Facebook'
      end
    end

    describe "Facebook suggest modal dialogue", :js=>true do
      scenario "should be displayed if I have not linked my account to facebook" do
        login_as :registered_user_who_hasnt_declined_fb
        suggestion_to_connect_to_facebook.should be_visible
      end

      scenario "should be not be displayed when I have declined the suggestion to link to Facebook", :js=>true do
        login_as :registered_user_who_hasnt_declined_fb
        suggestion_to_connect_to_facebook.should be_visible
        follow_decline_link
        page_header.follow_logout_link
        log_back_in
        suggestion_to_connect_to_facebook.should_not be_visible
      end

    end
  end

  context "When I already have linked my account to facebook previously" do

    scenario "I should be able to login using facebook and to existing account", :js=>true do
      login_as :registered_user_with_facebook_authentication
      page.should_not have_link 'Login to Civic Commons'
      page.should have_content "John Doe"
    end

    scenario "I should not be able to login using my existing account anymore", :js=>true do
      user = create_user :registered_user_with_facebook_authentication
      goto :login
      login_without_facebook user
      page.should have_content 'It looks like you registered using Facebook, please login with Facebook.'
    end

  end

  context "Facebook profile picture" do

    scenario "I should my facebook profile picture if I've connected to Facebook", :js=>true do
      login_as :registered_user, email: 'johnd@test.com', avatar_cached_image_url: '', avatar_url: ''
      connect_account_to_facebook
      page_header.user_profile_picture.should eq "https://graph.facebook.com/12345/picture"
    end
  end

  context "Forgot password" do
    scenario "I should see a modal dialog prompting me to login to facebook.", :js=>true do
      user = create_user :registered_user_with_facebook_authentication
      forgot_password_page.visit
      forgot_password_page.enter_email(user.email)
      forgot_password_page.click_submit
      wait_until { page.has_content? "we cannot reset your password because your account with The Civic Commons was registered using Facebook." }
    end
  end
  def connect_account_to_facebook
    begin_connecting_to_facebook
    submit
    reload_logged_in_user
  end
  def begin_connecting_to_facebook
    page_header.follow_settings_link :for => logged_in_user
    follow_connect_to_facebook_link
  end
  def follow_decline_link
    click_link "Continue without linking account"
  end
end
