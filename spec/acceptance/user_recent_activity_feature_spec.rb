require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')
WebMock.allow_net_connect!
ActiveRecord::Observer.enable_observers

Capybara.default_wait_time = 20


feature "User Recent Activity", %q{
  In order to display recent activty about the user
  As a current user
  I want to be able to see the most recent activity
} do

  let (:login_page)                   { LoginPage.new(page) }
  let (:user_edit_profile_page)       { UserEditProfilePage.new(page) }
  let (:user_profile_page)            { UserProfilePage.new(page) }

  def given_a_new_user
    @new_user = Factory.create(:normal_person)
  end

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


  scenario "Empty Recent Activity" do
    # Given a new user
    given_a_new_user

    # When I view their recent activity
    user_profile_page.visit_user(@new_user)

    # Then I will be notified they are just starting
    user_profile_page.should contain("#{@new_user.name} is just getting started")
  end

  scenario "Conversation Recent Activity" do
    # Given a new user
    given_a_new_user

    # and they created a conversation
    @conversation = Factory.create(:user_generated_conversation, :owner => @new_user, :title => "User Generated Title", :summary => "User Generated Summary")

    # When I view their recent activity
    user_profile_page.visit_user(@new_user)

    # Then I will see a conversation in their recent activity
    user_profile_page.should contain("User Generated Title")
    user_profile_page.should contain("User Generated Summary")
  end

  scenario "Conversation Recent Activity with a long Summary will be truncated" do
    # Given a new user
    given_a_new_user

    # and they created a conversation
    @conversation = Factory.create(:user_generated_conversation, :owner => @new_user, :title => "User Generated Title", 
                                   :summary => "User Generated Summary 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 CHOPOFF 1234567890")

    # When I view their recent activity
    user_profile_page.visit_user(@new_user)

    # Then I will see a conversation in their recent activity
    user_profile_page.should contain("User Generated Title")
    user_profile_page.should contain("User Generated Summary 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 CHOPOFF...")
  end

end

