require "spec_helper"

describe Notifier do
  context "email_changed" do
    def given_sending_a_changed_email_notification
      @notification = Notifier.email_changed('old-email@example.com','new-email@example.com').deliver
    end
    
    it "should send to the old email" do
      given_sending_a_changed_email_notification
      @notification.to.should contain 'old-email@example.com'
    end
    
    it "should have the correct subject subject" do
      given_sending_a_changed_email_notification
      @notification.subject.should contain "You've recently changed your email with The Civic Commons"
    end
    
  end

  context "survey_confirmation" do
    def given_sending_a_survey_confirmation
      @survey_response = FactoryGirl.create(:vote_survey_response)
      @notification = Notifier.survey_confirmation(@survey_response).deliver
    end
    it "should send it correctly" do
      given_sending_a_survey_confirmation
      @notification.body.should contain 'Thank for your vote on "This is a title"'
      @notification.body.should contain "Please check back"
    end
  end
end
