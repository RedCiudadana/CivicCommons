require 'spec_helper'

module Utilities
  describe PersonUtilities do

    context "when merging another account" do
      def given_a_person_with_email(email)
        person = FactoryGirl.create(:registered_user, :avatar => nil, :email => email)
      end

      after(:each) do
        Person.delete_all
      end

      before(:each) do
        @person = given_a_person_with_email "test1@example.com"
        @person_to_merge = given_a_person_with_email "test2@example.com"
      end

      it "will return false if the account is the same" do
        PersonUtilities.merge_account(@person, @person).should == false
      end

      it "will return true if the merge succeeds" do
        PersonUtilities.merge_account(@person, @person_to_merge).should == true
      end

      it "will rollback if a transaction fails" do
        FactoryGirl.create(:top_level_contribution, person: @person_to_merge)
        FactoryGirl.create(:contribution, person: @person_to_merge)
        FactoryGirl.create(:issue_contribution, person: @person_to_merge)
        FactoryGirl.create(:comment, person: @person_to_merge)
        @person_to_merge.contributions.length.should == 4

        # run a portion of the PersonUtilities.merge_account code to check that transactions work as expected
        # PersonUtilities.merge_account(@person, @person_to_merge)
        @person_to_merge.transaction do
          @person_to_merge.confirmed_at = nil
          @person_to_merge.save!

          @person_to_merge.contributions.each_with_index do |contribution, i|
            contribution.owner = @person.id
            contribution.save!
            if i == 1
              raise ActiveRecord::Rollback
            end
          end
        end # transaction

        Person.find(@person_to_merge.id).confirmed_at.should_not be_nil
        Person.find(@person.id).contributions.length.should == 0

        Contribution.delete_all
      end

      it "will unconfirm the person_to_merge" do
        PersonUtilities.merge_account(@person, @person_to_merge)
        Person.find(@person_to_merge.id).confirmed_at.should be_nil
      end

      it "will associate contributions to the person being merged into" do
        contribution = FactoryGirl.create(:top_level_contribution, person: @person_to_merge)
        conversation = contribution.conversation
        FactoryGirl.create(:contribution, person: @person_to_merge)
        FactoryGirl.create(:issue_contribution, person: @person_to_merge)
        FactoryGirl.create(:comment, person: @person_to_merge)
        FactoryGirl.create(:comment_with_unique_content, person: @person_to_merge)
        FactoryGirl.create(:suggested_action, person: @person_to_merge)
        FactoryGirl.create(:question, conversation: conversation, parent: contribution, person: @person_to_merge)
        FactoryGirl.create(:question_without_parent, conversation: conversation ,person: @person_to_merge)
        FactoryGirl.create(:answer, person: @person_to_merge)
        FactoryGirl.create(:attached_file, person: @person_to_merge)
        FactoryGirl.create(:link, person: @person_to_merge)
        FactoryGirl.create(:embedded_snippet, person: @person_to_merge)
        FactoryGirl.create(:embedly_contribution, conversation: conversation, parent: contribution, person: @person_to_merge)

        # create an array of the contribution IDs attributed to person_to_merge
        contribution_ids = @person_to_merge.contributions.collect do |contribution|
          contribution.id
        end

        PersonUtilities.merge_account(@person, @person_to_merge)

        # check the original contributions to see if the owner was updated correctly
        Contribution.find(contribution_ids).each do |contribution|
          contribution.owner.should == @person.id
        end

        Contribution.delete_all
      end

      it "will associate ratings to the person being merged into" do
        @contribution = FactoryGirl.create(:comment)
        @descriptor = FactoryGirl.create(:rating_descriptor)
        @rg = FactoryGirl.create(:rating_group, :contribution => @contribution, :person => @person_to_merge)
        @rating = FactoryGirl.create(:rating, :rating_group => @rg, :rating_descriptor => @descriptor)

        @rating.person.should == @person_to_merge
        PersonUtilities.merge_account(@person, @person_to_merge)
        Rating.find(@rating.id).person.should == @person
      end

      it "will associate conversations to the person being merged into" do
        conversation = FactoryGirl.build(:user_generated_conversation, person: @person_to_merge)
        conversation.should be_valid
        conversation.save

        conversation.person.should == @person_to_merge
        Conversation.find(conversation.id).person.should == @person_to_merge
        PersonUtilities.merge_account(@person, @person_to_merge)
        Conversation.find(conversation.id).person.should == @person
      end

      it "will associate subscriptions to the person being merged into" do
        @conversation_subscription = FactoryGirl.create(:conversation_subscription, person_id: @person_to_merge.id)
        @conversation_subscription.person.should == @person_to_merge

        PersonUtilities.merge_account(@person, @person_to_merge)
        subscription = Subscription.find_by_person_id(@person.id)
        subscription.subscribable.should == @conversation_subscription.subscribable
      end

      it "will associate visits to the person being merged into" do
        item = FactoryGirl.create(:issue, {:total_visits=>0, :recent_visits=>0, :last_visit_date=>nil})
        item.visit(@person_to_merge.id)
        item.total_visits.should == 1
        PersonUtilities.merge_account(@person, @person_to_merge)
        Visit.where('person_id = ?', @person_to_merge.id).should be_empty
        Visit.where('person_id = ?', @person.id).length.should == 1
      end

      it "will associate authored content_items to the person being merged into" do
        @topic = FactoryGirl.create(:topic)
        @attr = FactoryGirl.attributes_for(:content_item, topics: [@topic])
        @attr[:author] = @person_to_merge
        content_item = ContentItem.new(@attr)
        content_item.should be_valid
        content_item.save
        
        # create an array of the authored content_item IDs attributed to person_to_merge
        authored_content_item_ids = @person_to_merge.authored_content_items.collect do |content_item|
          content_item.id
        end
        authored_content_item_ids.length.should == 1
        
        # create an array of the content_item IDs attributed to person_to_merge

        PersonUtilities.merge_account(@person, @person_to_merge)

        # check the original content_items to see if the owner was updated correctly
        ContentItem.find(authored_content_item_ids).each do |content_item|
          content_item.person_id.should == @person.id
        end

        ContentItem.delete_all
      end
      
      it "will associate content_items_people to the person being merged into" do
        @content_item = FactoryGirl.create(:content_item)
        @content_item.add_person('host', @person_to_merge)
        # @content_item.save
        
        @person_to_merge.reload
        
        @content_item.reload
        
        @content_item.hosts.should == [@person_to_merge]
        @content_item.hosts.should_not == [@person]
        PersonUtilities.merge_account(@person, @person_to_merge)
        
        @content_item.reload
        @content_item.hosts.should == [@person]
        
        ContentItem.delete_all
      end

      it "will associate content_templates to the person being merged into" do
        @attr = FactoryGirl.attributes_for(:content_template)
        @attr[:author] = @person_to_merge
        content_template = ContentTemplate.new(@attr)
        content_template.should be_valid
        content_template.save

        # create an array of the content_template IDs attributed to person_to_merge
        content_template_ids = @person_to_merge.content_templates.collect do |content_template|
          content_template.id
        end
        content_template_ids.length.should == 1

        PersonUtilities.merge_account(@person, @person_to_merge)

        # check the original content_templates to see if the owner was updated correctly
        ContentTemplate.find(content_template_ids).each do |content_template|
          content_template.person_id.should == @person.id
        end

        ContentTemplate.delete_all
      end

      it "will associate managed_issue_pages to the person being merged into" do
        @attr = FactoryGirl.attributes_for(:managed_issue_page)
        @attr[:issue] = FactoryGirl.build(:managed_issue)
        @attr[:author] = @person_to_merge
        managed_issue_page = ManagedIssuePage.new(@attr)
        managed_issue_page.should be_valid
        managed_issue_page.save

        # create an array of the managed_issue_page IDs attributed to person_to_merge
        managed_issue_page_ids = @person_to_merge.managed_issue_pages.collect do |managed_issue_page|
          managed_issue_page.id
        end
        managed_issue_page_ids.length.should == 1

        PersonUtilities.merge_account(@person, @person_to_merge)

        # check the original managed_issue_pages to see if the owner was updated correctly
        ManagedIssuePage.find(managed_issue_page_ids).each do |managed_issue_page|
          managed_issue_page.person_id.should == @person.id
        end

        ManagedIssuePage.delete_all
      end

    end

  end
end
