require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')
WebMock.allow_net_connect!
ActiveRecord::Observer.enable_observers

Capybara.default_wait_time = 20

feature "User Recent Activity", %q{
  In order to display recent activty about the user
  As a current user
  I want to be able to see the most recent activity
} do

  let (:henry_ford)                   { Factory.create(:normal_person, :first_name => "Henry", :last_name => "Ford")}
  let (:alex_flemming)                { Factory.create(:normal_person)}
  let (:login_page)                   { LoginPage.new(page) }
  let (:user_profile_page)            { UserProfilePage.new(page) }


  def given_logged_in_as_henry_ford
    @user = logged_in_user
  end


  scenario "Empty Recent Activity" do
    visit_user_profile_for henry_ford
    activity_stream.should have_content "#{henry_ford.name} is just getting started"
  end

  scenario "Conversation Recent Activity" do
    henry_ford.create_conversation :title => "User Generated Title", :summary => "User Generated Summary"
    visit_user_profile_for henry_ford
    activity_stream.should have_content "User Generated Title"
    activity_stream.should have_content "User Generated Summary"
  end

  scenario "Contribution Recent Activity with a Parent Contribution" do
    parent_comment, henrys_comment = henry_ford.responds_to_comment(:title => "User Generated Contribution Title", :content => "User Generated Contribution Content")
    visit_user_profile_for henry_ford

    # The contribution will be in Henry Ford's recent activity as well as the parent comment
    activity_stream.should have_content("#{parent_comment.item_title}")
    activity_stream.should have_content("I responded to #{parent_comment.person_name}")
    activity_stream.should have_content("User Generated Contribution Content")
    activity_stream.should have_content(parent_comment.content)
  end

end

