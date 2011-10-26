require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')
WebMock.allow_net_connect!

Capybara.default_wait_time = 20


feature "User Settings", %q{
  In order to display relevant info about the user
  As a current user
  I want to be able to manage my user profile
} do

  let (:login_page)                   { LoginPage.new(page) }
  let (:user_edit_profile_page)       { UserEditProfilePage.new(page) }

  def given_logged_in_as_a_user
    @user = logged_in_user
  end

  scenario "Zipcode validation message on user profile if user had not previously added the zipcode" do
    # Given I'm logged in as a user
    given_logged_in_as_a_user

    # And previously I haven't had my zipcode added
    @user.zip_code = nil
    @user.save(:validate=>false)

    # When I visit my edit user profile page
    user_edit_profile_page.visit_user(@user)

    # Then I should see the validation on zipcode requirement
    user_edit_profile_page.should contain 'please enter zipcode, must be 5 characters or higher'
  end

  scenario "Zip Code required on user update on profile page" do
    # Given I'm logged in as a user
    given_logged_in_as_a_user

    # And previously I haven't had my zipcode added
    @user.zip_code = nil
    @user.save(:validate=>false)

    # And I visit the edit user profile page
    user_edit_profile_page.visit_user(@user)

    # When I have a blank zipcode on the form And I press submit
    user_edit_profile_page.click_submit

    # Then I should have validation error on zipcode
    user_edit_profile_page.should contain 'please enter zipcode, must be 5 characters or higher'
  end

end
