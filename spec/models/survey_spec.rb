require 'spec_helper'

describe Survey do
  context "Associations" do
    context "has_many :options" do
      it "should have many options" do
        Survey.reflect_on_association(:options).macro.should == :has_many
      end

      it "should have the class name as 'SurveyOption" do
        Survey.reflect_on_association(:options).options[:class_name].should == "SurveyOption"
      end

      it "should have foreign_key as 'survey_id" do
        Survey.reflect_on_association(:options).options[:foreign_key].should == 'survey_id'
      end

      it "should destroy dependent when it is destroyed" do
        Survey.reflect_on_association(:options).options[:dependent].should == :destroy
      end
    end
    
    it "should belongs to person" do
      should belong_to(:person)
    end

    it "should has one action as actionable" do
      should have_one(:action).dependent(:destroy)
    end
    
    it "should have many respondents" do
      should have_many(:respondents).through(:survey_responses)
    end

    context "belongs_to :surveyable" do
      it "should really belongs to surveyable" do
        Survey.reflect_on_association(:surveyable).macro.should == :belongs_to
      end

      it "should be polymorphic " do
        Survey.reflect_on_association(:surveyable).options.should == {:polymorphic=>true, :foreign_type=>"surveyable_type"}
      end
    end

    context "accepts_nested_attributes_for :options" do
      it "should correctly create nested models" do
        @survey = FactoryGirl.build(:survey)
        @survey.options_attributes = [{:title => 'option title here', :description => 'option description here', :nested => true}]
        @survey.save
        @survey.should be_valid
        SurveyOption.count.should == 1
      end

    end

    context "has_many survey_responses" do
      it "should have many survey_responses" do
        Survey.reflect_on_association(:survey_responses).macro == :has_many
      end

      it "should not destroy this object if it has dependencies" do
        Survey.reflect_on_association(:survey_responses).options[:dependent].should == :restrict
      end
    end

  end

  context "Validations" do
    before(:each) do
      @survey = Survey.create
    end
    it "should NOT validate presence of surveyable" do
      @survey.errors[:surveyable_id].should be_blank
      @survey.errors[:surveyable_type].should be_blank
    end
    it "should validate presence_of end_date" do
      @survey.errors[:end_date].should == ["can't be blank"]
    end
  end
  
  context "Single Table Inheritance" do
    it "can be a Vote" do
      Vote.superclass.should == Survey
    end
    it "can be a Poll" do
      Poll.superclass.should == Survey
    end
  end
  
  context "End Date" do
    it "should display the survey progress if show_progress is set to true AND end_date is less than today's date" do
      @survey = FactoryGirl.create(:survey, :end_date => 2.days.ago.to_date, :show_progress => true)
      @survey.end_date.should be_present
      @survey.show_progress_now?.should == true
    end
    it "should NOT display survey progress if show_progress is set to true AND end_date is later than Today's date" do
      @survey = FactoryGirl.create(:survey, :end_date => 2.days.from_now.to_date, :show_progress => true)
      @survey.show_progress_now?.should == false
    end
    it "should NOT display survey progress if show_progress is set to false" do
      @survey = FactoryGirl.create(:survey, :end_date => 2.days.from_now.to_date, :show_progress => false)
      @survey.show_progress_now?.should == false
    end
  end
  
  context "attached_to_conversation" do
    it "should show true if surveyable exists and if it is a Conversation" do
      @conversation = FactoryGirl.create(:conversation)
      @vote = FactoryGirl.build(:vote, :surveyable => @conversation)
      @vote.attached_to_conversation?.should be_true
    end
    it "should show false if surveyable is a Conversation" do
      @topic = FactoryGirl.create(:topic)
      @vote = FactoryGirl.build(:vote, :surveyable => @topic)
      @vote.attached_to_conversation?.should be_false
    end
    it "should not show false if surveyable doesn't exist" do
      @vote = FactoryGirl.build(:vote)
      @vote.attached_to_conversation?.should be_false
    end
    context 'conversation_id' do
      it "should return the right conversation id if attached is a conversation" do
        @conversation = FactoryGirl.create(:conversation)
        @vote = FactoryGirl.build(:vote, :surveyable => @conversation)
        @vote.conversation_id.should == @conversation.id
      end
      it "should not return any id if attached is not a conversation" do
        @issue = FactoryGirl.create(:issue)
        @vote = FactoryGirl.build(:vote, :surveyable => @issue)
        @vote.conversation_id.should be_nil
      end
    end
    
  end
  
  
  context "active?" do
    it "should be active when there is no start_date" do
      @survey = FactoryGirl.create(:survey, :show_progress => true)
      @survey.should be_active
    end
    it "should not be active when the start_date is in the future" do
      @survey = FactoryGirl.create(:survey, :show_progress => true, :start_date => 1.days.from_now.to_date)
      @survey.should_not be_active
    end
    it "should be active when the start_date is in the past" do
      @survey = FactoryGirl.create(:survey, :show_progress => true, :start_date => 1.days.ago.to_date)
      @survey.should be_active
    end
    it "should be active when the start_date is today" do
      @survey = FactoryGirl.create(:survey, :show_progress => true, :start_date => Date.today)
      @survey.should be_active
    end
  end
  
  context "expired?" do
    it "should not be expired when the end_date is in the future" do
      @survey = FactoryGirl.create(:survey, :show_progress => true, :end_date => 1.days.from_now.to_date)
      @survey.should_not be_expired
    end
    it "should be expired when the end_date is in the past" do
      @survey = FactoryGirl.create(:survey, :show_progress => true, :end_date => 1.days.ago.to_date)
      @survey.should be_expired
    end
    it "should not be expired when the end_date is today" do
      @survey = FactoryGirl.create(:survey, :show_progress => true, :end_date => Date.today)
      @survey.should_not be_expired
    end
  end
  describe "#days_until_end_date" do
    it "counts number of days to end date" do
      end_date = Date.today + 1.day
      @survey = FactoryGirl.create(:survey, :end_date => end_date, :show_progress => false)
      @survey.days_until_end_date.should == 1
    end
    it "is nil when end_date is today" do
      @survey = FactoryGirl.create(:survey, :end_date => Date.today, :show_progress => false)
      @survey.days_until_end_date.should be_nil
    end
  end

  describe "sending emails to survey respondents that the survey has ended" do
    context "sending to background job" do
      it "should send to background job on save" do
        @survey = FactoryGirl.create(:survey, :end_date => Date.today, :show_progress => false)
        Delayed::Job.count.should == 1
      end
      it "should send to the background job on update when end_date is changed" do
        @survey = FactoryGirl.create(:survey, :end_date => Date.today, :show_progress => false)
        @survey.end_date = 1.days.from_now.to_date
        @survey.save
        Delayed::Job.count.should == 2
      end
      it "should have the delayed job run at the end_date" do
        the_date = Date.today
        @survey = FactoryGirl.create(:survey, :end_date => the_date, :show_progress => false)
        Delayed::Job.last.run_at.to_date.should == the_date
      end
    end
    context "when running background job" do
      def given_a_survey_with_a_response
        @vote_survey_response = FactoryGirl.create(:vote_survey_response)
        @survey = @vote_survey_response.survey
        @person = @vote_survey_response.person
      end
      it "should send all email, if email notification has not been sent" do
        given_a_survey_with_a_response
        ActionMailer::Base.deliveries = []
        @survey.send_end_notification_email
        ActionMailer::Base.deliveries.count.should == 1
      end
      it "should set the end_notification_email_sent to true if email is sent" do
        given_a_survey_with_a_response
        @survey.send_end_notification_email
        @survey.end_notification_email_sent.should be_true
      end
      it "should not send any email, if email notification has been sent before" do
        given_a_survey_with_a_response
        ActionMailer::Base.deliveries = []
        @survey.end_notification_email_sent = true
        @survey.save
        @survey.send_end_notification_email
        ActionMailer::Base.deliveries.count.should == 0
      end
      it "should receive notifier" do
        given_a_survey_with_a_response
        Notifier.stub_chain(:survey_ended,:deliver)
        @survey.send_end_notification_email
      end
    end
  end
  
  describe "after_create_or_update on action" do
    describe "after_update" do
      it "should not modify the action model if Survey is saved and there is an attached conversation and it has not changed" do
        @conversation = FactoryGirl.create(:conversation)
        @vote = FactoryGirl.create(:vote, :surveyable => @conversation)
        @action = Action.first
        @action.conversation.should == @conversation
        @vote.save
        @action.reload.conversation.should == @conversation
      end
      it "should modify the action model if Survey is updated and surveyable has changed" do
        @conversation = FactoryGirl.create(:conversation)
        @conversation2 = FactoryGirl.create(:conversation)
        @vote = FactoryGirl.create(:vote, :surveyable => @conversation)
        @action = Action.first
        @action.conversation.should == @conversation
        @vote.surveyable = @conversation2
        @vote.save
        @action.reload.conversation.should == @conversation2
      end
    end
    describe "create_action" do
      it "should create the action model once a survey is created and there is an attached conversation" do
        @conversation = FactoryGirl.create(:conversation)
        FactoryGirl.create(:vote, :surveyable => @conversation)
        Action.first.should == Vote.first.action
      end
      it "should not create an action if survey is not attached to a conversation" do
        FactoryGirl.create(:vote)
        Action.count.should == 0
      end
    end
  end
end
