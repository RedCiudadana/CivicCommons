require 'spec_helper'

describe DigestService do
  before(:all) do
    # This is needed so that the vote ended related tests do not fail intermittently.
    Timecop.travel(DateTime.parse('01 Jun 2012 5AM'))
  end

  after(:all) do
    Timecop.return
  end

  describe "generate_digest_set" do
    before(:each) do

      #Contributor that talks a lot
      @contributor = FactoryGirl.create(:registered_user, :name => 'Big Talker', :avatar => nil)

      #Conversations
      @convo_fresh_with_subs = FactoryGirl.create(:conversation, :title => 'Fresh with Subscriptions')
      @convo_fresh_without_subs = FactoryGirl.create(:conversation, :title => 'Fresh without Subscriptions')
      @convo_stale_with_subs = FactoryGirl.create(:conversation, :title => 'Stale with Subscriptions')
      @convo_stale_without_subs = FactoryGirl.create(:conversation, :title => 'Stale without Subscriptions')

      #create instance of DigestService
      @service = DigestService.new
    end


    context "When users have opted out of the digest" do
      before(:each) do
        @person_unsubscribed_from_digest = FactoryGirl.create(:registered_user, :daily_digest => false,  :name => 'No Subscriptions', :avatar => nil)
      end

      it "Generates an empty set" do
        set = @service.generate_digest_set
        set.should be_empty
      end
    end


    context "When users have subscribed to conversations" do

      before(:each) do
        @person_with_subs = FactoryGirl.create(:registered_user, :name => 'I Subscribe', :daily_digest => true, :avatar => nil)

        #Subscriptions
        @sub_fresh = FactoryGirl.create(:conversation_subscription, :person => @person_with_subs, :subscribable => @convo_fresh_with_subs)
        @sub_stale = FactoryGirl.create(:conversation_subscription, :person => @person_with_subs, :subscribable => @convo_stale_with_subs)

        #Contributions
        FactoryGirl.create(:contribution, :person => @contributor, :conversation => @convo_stale_with_subs, :created_at => 2.days.ago)
        FactoryGirl.create(:contribution, :person => @contributor, :conversation => @convo_stale_without_subs, :created_at => 2.days.ago)

        #Reflections
        FactoryGirl.create(:reflection, :person => @contributor, :conversation => @convo_stale_with_subs, :created_at => 2.days.ago)
        FactoryGirl.create(:reflection, :person => @contributor, :conversation => @convo_stale_without_subs, :created_at => 2.days.ago)

        #Vote created
        @vote_created = FactoryGirl.create(:vote, :person => @contributor, :surveyable => @convo_stale_without_subs, :created_at => 2.days.ago)
        #Vote ended
        FactoryGirl.create(:vote, :person => @contributor, :surveyable => @convo_stale_without_subs, :end_date => 2.days.ago)
        #Vote response
        FactoryGirl.create(:vote_survey_response, :person => @contributor, :survey => @vote_created, :created_at => 2.days.ago)
      end

      context "No new contributions added yesterday" do
        it "should generate a digest set with a person but no contribution data" do
          set = @service.generate_digest_set
          set.should be_instance_of Hash
          @service.digest_set[@person_with_subs].should == []
        end
      end

      context "Vote Activities added yesterday" do
        before(:each) do
          #Vote created
          @vote_created_fresh_with_sub = FactoryGirl.create(:vote, :person => @contributor, :surveyable => @convo_fresh_with_subs, :created_at => 1.days.ago)
          @vote_created_fresh_without_sub = FactoryGirl.create(:vote, :person => @contributor, :surveyable => @convo_fresh_without_subs, :created_at => 1.days.ago)
          #Vote ended
          @vote_ended_fresh_with_sub = FactoryGirl.create(:vote, :person => @contributor, :surveyable => @convo_fresh_with_subs, :end_date => 1.days.ago)
          @vote_ended_fresh_without_sub = FactoryGirl.create(:vote, :person => @contributor, :surveyable => @convo_fresh_without_subs, :end_date => 1.days.ago)
          #Vote response
          @vote_response_fresh_with_sub = FactoryGirl.create(:vote_survey_response, :person => @contributor, :survey => @vote_created_fresh_with_sub, :created_at => 1.days.ago)
          @vote_response_fresh_without_sub = FactoryGirl.create(:vote_survey_response, :person => @contributor, :survey => @vote_created_fresh_without_sub, :created_at => 1.days.ago)
        end
        it "should have valid results" do
          set = @service.generate_digest_set
          set.should be_instance_of Hash
          set.should have(1).items
          set.should have_key(@person_with_subs)

          convos = set[@person_with_subs]
          convos.should be_instance_of Array

          convos.should have(1).items
          convos[0].first.should == @convo_fresh_with_subs
          convos[0].last.should_not be_blank
        end
        it "should include Vote created" do
          set = @service.generate_digest_set
          convos = set[@person_with_subs]
          convos[0].last.should be_include(@vote_created_fresh_with_sub)
          convos[0].last.should_not be_include(@vote_created_fresh_without_sub)
        end
        it "should include Vote Ended" do
          set = @service.generate_digest_set
          convos = set[@person_with_subs]
          convos[0].last.should be_include(@vote_ended_fresh_with_sub)
          convos[0].last.should_not be_include(@vote_ended_fresh_without_sub)
        end
        it "should include who Voted" do
          set = @service.generate_digest_set
          convos = set[@person_with_subs]
          convos[0].last.should be_include(@vote_response_fresh_with_sub)
          convos[0].last.should_not be_include(@vote_response_fresh_without_sub)
        end

      end

      context "Reflections added yesterday" do
        before(:each) do
          #Reflections
          @reflection_fresh_with_sub = FactoryGirl.create(:reflection, :person => @contributor, :conversation => @convo_fresh_with_subs, :created_at => 1.days.ago)
          @reflection_fresh_without_sub = FactoryGirl.create(:reflection, :person => @contributor, :conversation => @convo_fresh_without_subs, :created_at => 1.days.ago)
        end

        it "should include reflections" do
          set = @service.generate_digest_set
          set.should be_instance_of Hash
          set.should have(1).items
          set.should have_key(@person_with_subs)

          convos = set[@person_with_subs]
          convos.should be_instance_of Array

          convos.should have(1).items
          convos[0].first.should == @convo_fresh_with_subs
          convos[0].last.should == [@reflection_fresh_with_sub]
        end
      end

      context "Contributions were added Yesterday" do

        before(:each) do
          #Issue
          @fresh_issue = FactoryGirl.create(:issue)

          #Subscriptions
          @sub_fresh_issue = FactoryGirl.create(:issue_subscription, :person => @person_with_subs, :subscribable => @fresh_issue)

          #Contributions
          FactoryGirl.create(:issue_contribution, :person => @contributor, :created_at => 1.day.ago)
          FactoryGirl.create(:contribution, :person => @contributor, :conversation => @convo_fresh_with_subs, :created_at => 1.day.ago)
          FactoryGirl.create(:contribution, :person => @contributor, :conversation => @convo_fresh_without_subs, :created_at => 1.day.ago)
        end

        it "should generate a valid data set when there are fresh contributions and at least one valid subscriber" do

          set = @service.generate_digest_set

          set.should be_instance_of Hash
          set.should have(1).items
          set.should have_key(@person_with_subs)

          convos = set[@person_with_subs]
          convos.should be_instance_of Array
          convos.should have(1).items
          convos[0].first.should == @convo_fresh_with_subs
        end

        it "should not include contributions that were made on issues" do
          set = @service.generate_digest_set

          set.should be_an_instance_of Hash
          set.should have(1).items
          set[@person_with_subs].should_not include(@sub_fresh_issue)
        end

      end

    end

  end

  describe "DigestService#group_contributions_by_conversation" do

    it "Creates an array of contributions for the given conversation" do
      @person_with_subs = FactoryGirl.create(:registered_user, :name => 'I Subscribe', :daily_digest => true, :avatar => nil)
      @contributor = FactoryGirl.create(:registered_user, :name => 'Big Talker', :avatar => nil)
      @convo_fresh_with_subs = FactoryGirl.create(:conversation, :title => 'Fresh with Subscriptions')
      FactoryGirl.create(:conversation_subscription, person: @person_with_subs, subscribable: @convo_fresh_with_subs)
      @first_contribution = FactoryGirl.create(:contribution, :person => @contributor, :conversation => @convo_fresh_with_subs, :created_at => 1.day.ago)
      @second_contribution = FactoryGirl.create(:contribution, :person => @contributor, :conversation => @convo_fresh_with_subs, :created_at => 1.day.ago)
      @reflection_fresh_with_sub = FactoryGirl.create(:reflection, :person => @contributor, :conversation => @convo_fresh_with_subs, :created_at => 1.days.ago)

      digest = DigestService.new
      digest.generate_digest_set
      digest.digest_set[@person_with_subs][0][1].should be_an_instance_of Array
      digest.digest_set[@person_with_subs][0][1][0].should == @first_contribution
      digest.digest_set[@person_with_subs][0][1][1].should == @second_contribution
      digest.digest_set[@person_with_subs][0][1][2].should == @reflection_fresh_with_sub
    end

    it "creates an array of reflection for a given conversation" do
      @person_with_subs = FactoryGirl.create(:registered_user, :name => 'I Subscribe', :daily_digest => true, :avatar => nil)
      @convo_fresh_with_subs = FactoryGirl.create(:conversation, :title => 'Fresh with Subscriptions')
      FactoryGirl.create(:conversation_subscription, person: @person_with_subs, subscribable: @convo_fresh_with_subs)
      @reflection_fresh_with_sub = FactoryGirl.create(:reflection, :person => @person_with_subs, :conversation => @convo_fresh_with_subs, :created_at => 1.days.ago)

      digest = DigestService.new
      digest.generate_digest_set
      digest.digest_set[@person_with_subs][0][1].should be_an_instance_of Array
      digest.digest_set[@person_with_subs][0][1][0].should == @reflection_fresh_with_sub
    end

    it "creates an array of vote activities for a given conversation" do
      @person_with_subs = FactoryGirl.create(:registered_user, :name => 'I Subscribe', :daily_digest => true, :avatar => nil)
      @convo_fresh_with_subs = FactoryGirl.create(:conversation, :title => 'Fresh with Subscriptions')
      FactoryGirl.create(:conversation_subscription, person: @person_with_subs, subscribable: @convo_fresh_with_subs)
      # vote activities
      @vote_created_fresh_with_sub = FactoryGirl.create(:vote, :person => @person_with_subs, :surveyable => @convo_fresh_with_subs, :created_at => 1.days.ago)
      @vote_ended_fresh_with_sub = FactoryGirl.create(:vote, :person => @person_with_subs, :surveyable => @convo_fresh_with_subs, :end_date => 1.days.ago)
      @vote_response_fresh_with_sub = FactoryGirl.create(:vote_survey_response, :person => @person_with_subs, :survey => @vote_created_fresh_with_sub, :created_at => 1.days.ago)

      digest = DigestService.new
      digest.generate_digest_set
      digest.digest_set[@person_with_subs][0][1].should be_include @vote_created_fresh_with_sub
      digest.digest_set[@person_with_subs][0][1].should be_include @vote_ended_fresh_with_sub
      digest.digest_set[@person_with_subs][0][1].should be_include @vote_response_fresh_with_sub
    end

  end


  describe "process_daily_digest" do

    before(:each) do

      @person_with_subs = FactoryGirl.create(:registered_user, :name => 'I Subscribe', :daily_digest => true, :avatar => nil)
      @contributor = FactoryGirl.create(:registered_user, :name => 'Big Talker', :avatar => nil)
      @convo_fresh_with_subs = FactoryGirl.create(:conversation, :title => 'Fresh with Subscriptions')
      @vote_created_fresh_with_sub = FactoryGirl.create(:vote, :person => @contributor, :surveyable => @convo_fresh_with_subs, :created_at => 1.days.ago)
      @vote_created_fresh_with_sub.daily_digest_type = 'created'
      convo_array = [ [@convo_fresh_with_subs,
                        [ FactoryGirl.create(:contribution, :person => @contributor, :conversation => @convo_fresh_with_subs, :created_at => 1.day.ago),
                          FactoryGirl.create(:reflection, :person => @person_with_subs, :conversation => @convo_fresh_with_subs, :created_at => 1.days.ago),
                          @vote_created_fresh_with_sub,
                          FactoryGirl.create(:vote, :person => @person_with_subs, :surveyable => @convo_fresh_with_subs, :end_date => 1.days.ago),
                          FactoryGirl.create(:vote_survey_response, :person => @person_with_subs, :survey => @vote_created_fresh_with_sub, :created_at => 1.days.ago)
                           ] ] ]
      @digest_set = {
        @person_with_subs => convo_array
      }

      ActionMailer::Base.deliveries.clear
    end


    it "should send one email for each person in the set" do
      service = DigestService.new
      service.process_daily_digest(@digest_set)
      ActionMailer::Base.deliveries.length.should == @digest_set.size
    end

    it "should not send any emails when the data set is empty" do
      service = DigestService.new
      @digest_set = {}
      service.process_daily_digest(@digest_set)
      ActionMailer::Base.deliveries.length.should == 0
    end

    it "should not send any emails when the subscribers conversation array is empty" do
      service = DigestService.new
      @digest_set[@person_with_subs] = []
      service.process_daily_digest(@digest_set)
      ActionMailer::Base.deliveries.length.should == 0
    end

  end

  describe "send_digest" do
    before(:each) do

      @person_with_subs = FactoryGirl.create(:registered_user, :name => 'I Subscribe', :daily_digest => true, :avatar => nil)
      @convo_fresh_with_subs = FactoryGirl.create(:conversation, :title => 'Fresh with Subscriptions')
      FactoryGirl.create(:conversation_subscription, person: @person_with_subs, subscribable: @convo_fresh_with_subs)

      ActionMailer::Base.deliveries.clear
    end
    context "vote activities" do
      before(:each) do
        # vote activities
        @vote_created_fresh_with_sub = FactoryGirl.create(:vote, :person => @person_with_subs, :surveyable => @convo_fresh_with_subs, :created_at => 1.days.ago)
        @vote_ended_fresh_with_sub = FactoryGirl.create(:vote, :person => @person_with_subs, :surveyable => @convo_fresh_with_subs, :end_date => 1.days.ago)
        @vote_response_fresh_with_sub = FactoryGirl.create(:vote_survey_response, :person => @person_with_subs, :survey => @vote_created_fresh_with_sub, :created_at => 1.days.ago)
      end
      it "should successfully send the emails for votes created " do
        DigestService.send_digest
        ActionMailer::Base.deliveries.last.body.should =~ /created a vote/i
      end
      it "should successfully send the emails for votes ended " do
        DigestService.send_digest
        ActionMailer::Base.deliveries.last.body.should =~ /a vote has ended/i
      end
      it "should successfully send emails for vote responses" do
        DigestService.send_digest
        ActionMailer::Base.deliveries.last.body.should =~ /You voted on/i
      end
    end

    context "petitions activity" do
      before(:each) do
        @petition = FactoryGirl.create(:petition, :person => @person_with_subs, :conversation => @convo_fresh_with_subs, :created_at => 1.days.ago)
        FactoryGirl.create(:petition_signature, :person => @person_with_subs, :petition => @petition, :created_at => 1.days.ago)
      end
      it "should successfully send the emails for petitions created " do
        DigestService.send_digest
        ActionMailer::Base.deliveries.last.body.should =~ /You created a petition/i
      end
      it "should successfully send the emails for petition signatures created " do
        DigestService.send_digest
        ActionMailer::Base.deliveries.last.body.should =~ /You signed a petition/i
      end
    end

  end

end
