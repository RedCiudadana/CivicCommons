require 'acceptance/acceptance_helper'

feature " Opportunity Votes", %q{
  As an visitor or user
  When I want participate in an opportunity votes
  I should be able to create and view votes, make a vote, and more.
} do
  
  FIRST_TITLE = 'First title here'
  FIRST_DESCRIPTION = 'First description here'
  SECOND_TITLE = 'Second title here'
  SECOND_DESCRIPTION = 'Second description here'
  
    
  def given_a_conversation
    @conversation = FactoryGirl.create(:conversation)
  end
  
  def given_a_vote(options={})
    @vote = FactoryGirl.create(:vote, options)
  end
  
  def given_a_vote_with_a_conversation(options={})
    @conversation = given_a_conversation
    @vote = given_a_vote(options.merge({:surveyable => @conversation}))
  end
  
  def given_a_vote_with_options_and_conversations(options={})
    @conversation = given_a_conversation
    @vote = given_a_vote(options.merge({:surveyable => @conversation}))
    @survey_option1 = FactoryGirl.create(:survey_option, :position => 1, :survey => @vote)
    @survey_option2 = FactoryGirl.create(:survey_option, :position => 2, :survey => @vote)
    @survey_option3 = FactoryGirl.create(:survey_option, :position => 3, :survey => @vote)
    @survey_option4 = FactoryGirl.create(:survey_option, :position => 4, :survey => @vote)
  end
  
  def given_a_vote_with_options_and_conversations_and_a_survey_response(person)
    given_a_vote_with_options_and_conversations(:show_progress => true)
    @survey_response = FactoryGirl.create(:survey_response,:survey => @vote, :person => person)
    @survey_response.selected_survey_options.create(:survey_option => @survey_option1, :position => 1)
    @survey_response.selected_survey_options.create(:survey_option => @survey_option2, :position => 2)
    @person2 = FactoryGirl.create(:registered_user)
    @survey_response2 = FactoryGirl.create(:survey_response,:survey => @vote, :person => @person2)
    @survey_response2.selected_survey_options.create(:survey_option => @survey_option2, :position => 1)
    @survey_response2.selected_survey_options.create(:survey_option => @survey_option3, :position => 2)
    
  end
  
  scenario "Ability to display a list of actions for votes.", :js => true do
    given_a_vote_with_a_conversation(:title => 'Vote title here')
    login_as :person
    visit conversation_actions_path(@conversation)
    current_page.should have_content('Vote title here')
  end
  
  scenario "Ability to create a vote from an opportunity actions page", :js => true do
    given_a_conversation
    login_as :person
    visit conversation_actions_path(@conversation)
    set_current_page_to :actions
    follow_suggest_an_action_link
    follow_take_a_vote_link
    current_page.should have_content 'New Vote'
    current_page.should have_content "I'm ready to submit my vote. I understand that once this is submitted that I cannot make any more changes."
  end
  
  scenario "Ability to add an option on the new votes page", :js => true do
    given_a_vote_with_a_conversation(:title => 'Vote title here')
    login_as :person
    visit new_conversation_vote_path(@conversation)
    set_current_page_to :new_opportunity_vote
    current_page.should have_selector '.survey-option', :count => 1
    follow_add_option_link
    current_page.should have_selector '.survey-option', :count => 2
    click_publish_invalid_vote_button
    current_page.should have_content 'There were errors saving this vote.'
  end
  
  scenario "Ability to delete an option on the new votes page", :js => true do
    given_a_vote_with_a_conversation(:title => 'Vote title here')
    login_as :person
    visit new_conversation_vote_path(@conversation)
    set_current_page_to :new_opportunity_vote
    current_page.should have_selector '.survey-option', :count => 1
    follow_delete_option_link
    accept_alert
    current_page.should_not have_selector '.survey-option'
    click_publish_invalid_vote_button
    current_page.should have_content 'There were errors saving this vote.'
  end
  
  scenario "Ability to sort options", :js => true do    
    given_a_vote_with_a_conversation(:title => 'Vote title here')
    login_as :person
    visit new_conversation_vote_path(@conversation)
    set_current_page_to :new_opportunity_vote
    follow_add_option_link
    current_page.should have_selector '.survey-option', :count => 2
    
    # fill in the two fields accordingly
    current_page.fill_in_title_field_for(1, FIRST_TITLE)
    current_page.fill_in_wysywig_description_field_for(1,FIRST_DESCRIPTION)    
    current_page.fill_in_title_field_for(2,SECOND_TITLE)
    current_page.fill_in_wysywig_description_field_for(2,SECOND_DESCRIPTION)
    
    # reorder it so that 1st one is on the second.
    current_page.reorder_option(1,2)
    
    click_publish_invalid_vote_button

    #verify that first is in the second order
    current_page.find_title_field_for(1).value.should =~ Regexp.new(SECOND_TITLE)
    current_page.find_description_field_for(1).value.should =~ Regexp.new(SECOND_DESCRIPTION)    
    current_page.find_title_field_for(2).value.should =~ Regexp.new(FIRST_TITLE)
    current_page.find_description_field_for(2).value.should =~ Regexp.new(FIRST_DESCRIPTION)
  end
  
  scenario "Ability to select, rank, and cast votes", :js => true do
    given_a_vote_with_options_and_conversations
    login_as :person
    visit conversation_vote_path(@conversation,@vote)
    set_current_page_to :select_options_opportunity_vote 
    # select 2 options
    current_page.select_option(2)
    current_page.select_option(4)
    # press continue
    click_continue_button
    # reorder so that the first one is the second
    current_page.reorder_option(1,2)
    # press cast vote

    click_cast_vote_button
    # then it should redirect to the vote page
    sleep 1
    current_page.current_path.should == conversation_vote_path(@conversation,@vote)
  end
  
  scenario "Ability to vote, but there are errors when submitting", :js => true do
    given_a_vote_with_options_and_conversations
    login_as :person
    
    # submitting with too many votes
    visit conversation_vote_path(@conversation,@vote)
    set_current_page_to :select_options_opportunity_vote 
    # select 4 options
    current_page.select_option(1)
    current_page.select_option(2)
    current_page.select_option(3)
    current_page.select_option(4)
    # press continue
    click_continue_with_invalid_options_button
    current_page.should have_content 'You cannot select more than 3 option(s)'
    
    # submitting with no votes
    visit conversation_vote_path(@conversation,@vote)
    click_continue_with_invalid_options_button
    current_page.should have_content 'You must select at least one option'
  end
  
  scenario "View vote results", :js => true do
    login_as :person
    given_a_vote_with_options_and_conversations_and_a_survey_response(logged_in_user)
    @vote.end_date = 3.day.ago
    @vote.save
    @vote.reload
    visit conversation_vote_path(@conversation,@vote)
    set_current_page_to :opportunity_vote 
    sleep 1
    current_page.should have_selector '.voting-results'
    current_page.should have_selector '.vote-container', :count => 4
    current_page.should have_selector '.vote-row.voted', :count => 2
  end
  
  scenario "Visitor should be able to view a vote permalink without logging in" do
    given_a_vote_with_options_and_conversations(:max_selected_options => 1)
    visit conversation_vote_path(@conversation,@vote)
    set_current_page_to :select_options_opportunity_vote
    current_page.should have_content 'register for an account'
    current_page.should have_content 'Step 1:'
    current_page.should have_content 'Please select up to 1 option' 
    current_page.select_option(1)
    click_continue_button
    #should prompt login
    current_page.should have_content 'Login'
  end

end