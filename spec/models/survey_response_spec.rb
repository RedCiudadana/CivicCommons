require 'spec_helper'

describe SurveyResponse do
  context "Associations" do
    it "should has many selected_survey_options" do
      SurveyResponse.reflect_on_association(:selected_survey_options).macro.should == :has_many
    end
    
    it "should destroy selected_survey_options dependents" do
      SurveyResponse.reflect_on_association(:selected_survey_options).options[:dependent].should == :destroy
    end
    
    it "should belong to person" do
      SurveyResponse.reflect_on_association(:person).macro.should == :belongs_to
    end
    
    it "should belong_to survey" do
      SurveyResponse.reflect_on_association(:survey).macro.should == :belongs_to
    end
  end

  context "Validations" do
    before(:each) do
      @survey_response = SurveyResponse.create
    end
    it "should validate presence of person_id" do
      @survey_response.errors[:person_id].should == ["can't be blank"]
    end
    it "should validate uniqueness of person_id and survey_id" do
      @survey_response1 = FactoryGirl.create(:survey_response)
      @survey_response2 = @survey_response1.clone
      @survey_response2.valid?
      @survey_response2.errors[:person_id].should == ["already exists"]
    end
    context "selected_should_be_under_max_selected_options" do
      def given_survey_with_options
        @survey = FactoryGirl.create(:survey,:max_selected_options => 2)
        @option1 = FactoryGirl.create(:survey_option,:survey_id  => @survey.id)
        @option2 = FactoryGirl.create(:survey_option,:survey_id  => @survey.id)
        @option3 = FactoryGirl.create(:survey_option,:survey_id  => @survey.id)
        @option4 = FactoryGirl.create(:survey_option,:survey_id  => @survey.id)
        @survey.reload
      end
      it "should not allow for more than max_selected_options" do
        given_survey_with_options
        @survey_response = FactoryGirl.build(:survey_response, :survey_id => @survey.id)
        @survey_response.selected_option_ids = [@option1.id,@option2.id,@option3.id]
        @survey_response.valid?
        @survey_response.errors[:selected_option_ids].include?('You cannot select more than 2 option(s)').should be_true
      end
      it "should allow it when it's less than or equal to max_selected_options" do
        given_survey_with_options
        @survey_response = FactoryGirl.build(:survey_response, :survey_id => @survey.id)
        @survey_response.selected_option_ids = [@option1.id,@option2.id]
        @survey_response.valid?
        @survey_response.errors[:selected_option_ids].should be_blank
      end
    end
  end
  
  context "scope" do
    context "sort_last_created_first" do
      def given_survey_responses
        @survey_response1 = FactoryGirl.create(:survey_response, :created_at => Date.today)
        @survey_response2 = FactoryGirl.create(:survey_response, :created_at => 1.days.ago)
      end
      it "should sort by last created at" do
        given_survey_responses
        SurveyResponse.sort_last_created_first.all.should == [@survey_response1,@survey_response2]
      end
    end
  end
  
  context "conversation_id" do
    it "should return the correct conversation_id" do
      @conversation = FactoryGirl.create(:conversation)
      @survey = FactoryGirl.create(:vote, :surveyable => @conversation)
      @survey_response = FactoryGirl.create(:survey_response, :survey => @survey)
      @survey_response.conversation_id.should_not be_nil
      @survey_response.conversation_id.should == Conversation.last.id
    end
  end

end