require 'spec_helper'
include ControllerMacros

describe SurveysController do
  before(:each) do
    login_user
  end

  describe "GET show" do
    describe "User have not voted yet" do
      it "should render the show_vote template if it is a 'vote'" do
        survey = Factory.create(:survey)
        get :show, :id => survey.id
        response.should render_template('surveys/show_vote')
      end
    end

    describe "user not allowed to vote" do
      it "should show progress if show_progress toggle is on" do
        survey = Factory.create(:survey, show_progress: true)
        Factory.create(:vote_survey_response, person: @user, survey: survey)
        get :show, :id => survey.id
        response.should render_template('surveys/show_vote_show_progress')
      end

      it "should not show progress if the show_progress toggle is off" do
        survey = Factory.create(:survey, show_progress: false)
        Factory.create(:vote_survey_response, person: @user, survey: survey)
        get :show, :id => survey.id
        response.should render_template('surveys/show_vote_hide_progress')
      end
    end

    describe "survey inactive" do
      it "should render the inactive if not yet survey start_date" do
        survey = Factory.create(:survey, start_date: Date.today + 1.day)
        get :show, :id => survey.id
        response.should render_template('surveys/show_vote_inactive')
      end

      it "should render normally if past survey start_date" do
        survey = Factory.create(:survey, start_date: Date.today - 1.day)
        get :show, :id => survey.id
        response.should_not render_template('surveys/show_vote_inactive')
      end
    end
  end

  describe "find_survey" do
    it "should return the survey" do
      survey = Factory.create(:survey)
      get :show, :id => survey.id
      assigns[:survey_response_presenter].survey_response.survey_id.should == survey.id
    end
  end

  describe "create_response" do
    describe "post" do
      describe "when confirmed" do
        before(:each) do
          @survey = Factory.create(:survey_with_options)
        end

        it "should render the show action when successfully saved" do
          post :create_response, :id => @survey.id, :survey_response_presenter => {
            selected_option_1_id: @survey.options.first.id
          }
          response.should render_template(:action => :show)
        end

        it "should set flash[:vote_successful] as true when successfully saved" do
          xhr :post, :create_response, :id => @survey.id, :survey_response_presenter => {
            confirmed: true
          }
          flash[:vote_successful].should be_true
        end

        it "should redirect to show_ template when there is an error" do
          xhr :post, :create_response, :id => @survey.id, :survey_response_presenter => {
            confirmed: true,
            selected_option_1_id: @survey.options.first.id
          }

          # since we only allow one vote per person, the second one should fail
          xhr :post, :create_response, :id => @survey.id, :survey_response_presenter => {
            confirmed: true,
            selected_option_1_id: @survey.options.first.id
          }
          response.body.should == 'document.location = \'http://test.host' + vote_path(@survey.id) + '\';'
        end
      end

      describe "when not confirmed" do
        before(:each) do
          @survey = Factory.create(:survey_with_options)
        end

        it "should render the vote confirmation partial when format is js" do
          xhr :post, :create_response, :id => @survey.id, :survey_response_presenter => {
            selected_option_1_id: @survey.options.first.id
          }
          response.should render_template('/surveys/_vote_response_confirmation')
        end

        it "should render nothing vote confirmation partial when format is html" do
          post :create_response, :id => @survey.id, :survey_response_presenter => {
            selected_option_1_id: @survey.options.first.id
          }
          response.body.should == 'Javascript needs to be turned on to vote'
        end

      end

    end
  end

  describe "vote_successful" do
    it "should render the correct template" do
      get :vote_successful
      response.should render_template('surveys/vote_successful')
    end
  end
end
