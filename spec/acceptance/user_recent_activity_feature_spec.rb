require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')
WebMock.allow_net_connect!
ActiveRecord::Observer.enable_observers

Capybara.default_wait_time = 20

feature "User Recent Activity", %q{
  In order to display recent activty about the user
  As a current user
  I want to be able to see the most recent activity
} do

  let (:a_user)                       { Factory.create(:normal_person)}
  let (:login_page)                   { LoginPage.new(page) }
  let (:user_profile_page)            { UserProfilePage.new(page) }


  def given_logged_in_as_a_user
    @user = logged_in_user
  end


  scenario "Empty Recent Activity" do
    # given_a_user
    # when_I_visit_the_users_profile
    user_profile_page.visit_user(a_user)

    # then_I_should_see_they_are_just_getting_started_in_their_recent_activity_stream
    within('.main-content') do
      user_profile_page.should contain("#{a_user.name} is just getting started")
    end
  end

  scenario "Conversation Recent Activity" do
    # Given a new user
    # and the user created a conversation
    @conversation = Factory.create(:user_generated_conversation, :owner => a_user, :title => "User Generated Title", :summary => "User Generated Summary")

    # When I view their recent activity
    user_profile_page.visit_user(a_user)

    # Then I will see a conversation in their recent activity
    user_profile_page.should contain("User Generated Title")
    user_profile_page.should contain("User Generated Summary")
  end

  scenario "Conversation Recent Activity with a long Summary will be truncated" do
    # Given a new user
    # and the user created a conversation
    @conversation = Factory.create(:user_generated_conversation, :owner => a_user, :title => "User Generated Title",
                                   :summary => "User Generated Summary 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 CHOPOFF 1234567890")

    # When I view their recent activity
    user_profile_page.visit_user(a_user)

    # Then I will see a conversation in their recent activity
    user_profile_page.should contain("User Generated Title")
    user_profile_page.should contain("User Generated Summary 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 CHOPOFF...")
  end

  scenario "Contribution Recent Activity with a Parent Contribution" do
    # Given a new user
    # and they created a contribution
    @parent_contribution = Factory.create(:comment, :title => "Parent Contribution Title", :content => "Parent Contribution Content")
    @contribution = Factory.create(:comment, :person => a_user, :parent => @parent_contribution, :conversation => @parent_contribution.conversation, :title => "User Generated Contribution Title", :content => "User Generated Contribution Content")

    # When I view their recent activity
    user_profile_page.visit_user(a_user)

    # Then I will see a contribution in their recent activity
    user_profile_page.should contain("#{@parent_contribution.item_title}")
    user_profile_page.should contain("I responded to #{@parent_contribution.person_name}")
    user_profile_page.should contain("User Generated Contribution Content")
    user_profile_page.should contain("Parent Contribution Content")
  end

end

