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
  let (:b_user)                       { Factory.create(:normal_person)}
  let (:login_page)                   { LoginPage.new(page) }
  let (:user_profile_page)            { UserProfilePage.new(page) }


  def given_logged_in_as_a_user
    @user = logged_in_user
  end


  scenario "Empty Recent Activity" do
    visit_user_profile_for a_user
    activity_stream.should have_content "#{a_user.name} is just getting started"
  end

  scenario "Conversation Recent Activity" do
    a_user.create_conversation :title => "User Generated Title", :summary => "User Generated Summary"
    visit_user_profile_for a_user
    activity_stream.should have_content "User Generated Title"
    activity_stream.should have_content "User Generated Summary"
  end

  #scenario "Conversation Recent Activity with a long Summary will be truncated" do
    ## Given a new user
    ## and the user created a conversation
    #conversation = Factory.create(:user_generated_conversation, :owner => a_user, :title => "User Generated Title",
                                   #:summary => "User Generated Summary 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 CHOPOFF 1234567890")

    ## When I view their recent activity
    #user_profile_page.visit_user(a_user)

    ## Then I will see a conversation in their recent activity
    #user_profile_page.should contain("User Generated Title")
    #user_profile_page.should contain("User Generated Summary 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 1234567890 CHOPOFF...")
  #end

  scenario "Contribution Recent Activity with a Parent Contribution" do
    parent_contribution = b_user.create_comment :title => "Parent Contribution Title", :content => "Parent Contribution Content"
    a_user.create_comment :parent => parent_contribution, :conversation => parent_contribution.conversation, :title => "User Generated Contribution Title", :content => "User Generated Contribution Content"
    a_user.create_conversation :title => "User Generated Title", :summary => "User Generated Summary"
    visit_user_profile_for a_user

    # Then I will see a contribution in their recent activity
    activity_stream.should have_content("#{parent_contribution.item_title}")
    activity_stream.should have_content("I responded to #{parent_contribution.person_name}")
    activity_stream.should have_content("User Generated Contribution Content")
    activity_stream.should have_content("Parent Contribution Content")
  end

end

