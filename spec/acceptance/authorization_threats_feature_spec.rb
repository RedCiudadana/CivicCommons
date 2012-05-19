require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

feature "Authorization Threats", %q{
  As an attacker
  I want to circumvent authorization rules
  So I can access protected parts of the site
} do

  describe "when not logged in" do

    # Given an admin user exists
    let :admin do
      FactoryGirl.create(:admin_person)
    end

    background do
      sign_out
    end

    scenario "I cannot access a user profile page" do
      visit edit_user_path(admin)
      should_not_be_on edit_user_path(admin)
      should_be_on community_path
    end

    scenario "I cannot access the admin pages" do
      visit admin_root_path
      should_not_be_on admin_root_path
      should_be_on new_person_session_path
    end

  end

  describe "when logged in" do

    # Given an admin user exists
    let :admin do
      FactoryGirl.create(:admin_person)
    end


    background do
      login_as :registered_user
    end

    scenario "I cannot access a user profile page" do
      visit edit_user_path(admin)
      should_not_be_on edit_user_path(admin)
      should_be_on community_path
    end

    scenario "I cannot access the admin pages" do
      visit admin_root_path
      should_not_be_on admin_root_path
      should_be_on root_path
    end

  end

end
