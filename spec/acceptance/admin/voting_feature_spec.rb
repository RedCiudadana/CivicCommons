require 'acceptance/acceptance_helper'

WebMock.allow_net_connect!
Capybara.default_wait_time = 10


feature "Voting Admin", %q{
  In order to Administer Votes
  As a an Admin user
  I want to access the survey admin feature
} do

  
  def given_an_existing_issue
    @issue = FactoryGirl.create(:issue)
  end
  
  def given_a_survey_with_responses
    @survey_response = FactoryGirl.create(:vote_survey_response)
    @survey = @survey_response.survey
  end
  
  let(:admin_surveys_page){ AdminSurveysPage.new(page)} 
  let(:admin_new_survey_page){AdminNewSurveyPage.new(page)}
  let(:admin_survey_progress_page){AdminSurveyProgressPage.new(page)}
    

  scenario "See an option to add a survey" do
    login_as :admin
    
    # When I go to the admin page
    admin_surveys_page.visit
    
    # Then I will see an option to add a survey
    admin_surveys_page.should have_link 'Add Survey', :href => new_admin_survey_path
  end
  
  scenario "Survey and Survey option sections" do
    login_as :admin
    
    # And I am on the admin page
    admin_surveys_page.visit
    
    # When I click on add survey
    admin_surveys_page.click_new_survey
    
    # Then I should see a new survey form
    admin_new_survey_page.should have_selector("form", :action => admin_surveys_path, :method => "post")
    
    # and there will be two parts survey and survey options
    admin_new_survey_page.should have_selector("form", :action => admin_surveys_path, :method => "post") do |form|
      form.should have_selector("input#survey_title", :name => "survey[title]")
      form.should have_selector("input#survey_options_attributes_0_title", :name => "survey[options_attributes][0][title]")
    end
  end
  
  scenario "filling in the survey informations" do
    login_as :admin
    
    # And I have an existing Issue
    given_an_existing_issue
    
    # When I am on the survey form
    admin_new_survey_page.visit
    
    # And I must fill in: title,and end date
    admin_new_survey_page.fill_in_survey_fields
    
    # and max options defaults to three unless reset by admin
    admin_new_survey_page.should have_field(:max_selected_option,:value => 3)
    
    # and I can set the survey as show progress or not (it defaults as off)
    admin_new_survey_page.should have_field(:show_progress,:value => nil)
    
    # and I can set a start date
    admin_new_survey_page.select_date('start_date', 1.day.ago.to_date)
    
    # and I click submit
    admin_new_survey_page.click_create_survey
        
    # Then the survey should be successfully created
    page.should have_content 'Survey was successfully created.'
  end
  
  scenario "Create the survey options" do
    login_as :admin
    
    # When I am on the survey form
    admin_new_survey_page.visit
    
    # And I have filled in the Survey related fields
    admin_new_survey_page.fill_in_survey_fields
    
    # Then I can create option title
    admin_new_survey_page.should have_selector('input#survey_options_attributes_0_title')
    admin_new_survey_page.fill_in('survey[options_attributes][0][title]', :with => 'title here')
    
    # and I can use a wyswig editor to create option descriptions
    admin_new_survey_page.fill_in('survey[options_attributes][0][description]', :with => 'description here')
    
    # and I can assign the option position to sort how it appears in default
    admin_new_survey_page.fill_in('survey[options_attributes][0][position]', :with => 1)
    
    # When I click on the create button
    admin_new_survey_page.click_create_survey
    
    # Then the survey should be created
    Survey.count.should == 1
    
    # And the Survey option should be created
    Survey.last.options.count.should == 1
  end
  
  scenario "redirecting to the admin's survey info page" do
    # Given that I am an admin who has completed creating a survey
    login_as :admin
    admin_new_survey_page.visit
    admin_new_survey_page.fill_in_survey_fields
    
    # When I click on the ‘create survey’ button
    admin_new_survey_page.click_create_survey
    
    # Then I should be redirected to the survey information page in the admin section
    page.should have_content 'Survey was successfully created.'
    page.should have_content 'Title here'
  end
  
  scenario "Getting to a survey page and editing it" do
    # Given that I am an admin who has completed creating a survey 
    login_as :admin
    admin_new_survey_page.visit
    admin_new_survey_page.fill_in_survey_fields
    admin_new_survey_page.click_create_survey
    
    # When I select the survey in the admin survey list
    admin_surveys_page.visit
    admin_surveys_page.click_edit_on_a_survey(Survey.last)
    
    # Then I can get to the survey page and edit it
    page.should have_content 'Editing survey'
    page.should have_selector("form", :action => admin_survey_path(Survey.last), :method => "post") do |form|
      form.should have_selector("input#survey_title", :name => "survey[title]")
      form.should have_selector("input#survey_options_attributes_0_title", :name => "survey[options_attributes][0][title]")
    end    
  end
  
  scenario "Survey progress page" do
    # Given I am an admin 
    login_as :admin
    
    # And a survey with responses
    given_a_survey_with_responses
    
    # When I go to the surveys page 
    admin_surveys_page.visit
    
    # Then I should see the survey progress link
    admin_surveys_page.should have_link "view"
    
    # When I click on the survey progress link
    admin_surveys_page.click_link "view"
    
    # Then I should be on the survey progress page
    page.current_path.should == progress_admin_survey_path(@survey)
    
    # And I should see the survey info
    admin_survey_progress_page.should have_content 'Showing survey progress'
    admin_survey_progress_page.should have_content 'Title: This is a title'
    
    # And I should see the survey progress chart
    admin_survey_progress_page.should have_content 'Progress Bar'
    admin_survey_progress_page.should have_selector 'div.survey-options ul.survey_results'
    
    # And I should see the respondents of the survey
    admin_survey_progress_page.should have_content 'Respondents'
    admin_survey_progress_page.should have_xpath("//h1[contains(.,'Respondents')]/following-sibling::*[contains(.,'John Doe')]", :count => 1)
  end
  
  scenario  do
    pending 'needs clarification'
    # Given that I am an admin who has completed creating a survey
    # When I click on the ‘create survey’ button
    # Then I should be redirected to the admins survey page
  end
end
