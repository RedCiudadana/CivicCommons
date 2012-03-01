require 'spec_helper'

describe Opportunity do
  describe "factories" do
    it "are valid" do
      Factory.build(:opportunity).should be_valid
      Factory.create(:opportunity).should be_valid
    end
  end

  describe "associations" do
  	it "has_one conversation" do
  	  Opportunity.reflect_on_association(:conversation).macro == :has_one
    end
  end

  describe "delegates" do
    let(:opportunity) do
      Factory.build(:opportunity)
    end
    it "responds to :cached_slug" do
      opportunity.respond_to?(:cached_slug).should be_true
    end
    it "responds to :image" do
      opportunity.respond_to?(:image).should be_true
    end
    it "responds to :participants" do
      opportunity.respond_to?(:participants).should be_true
    end
    it "responds to :summary" do
      opportunity.respond_to?(:summary).should be_true
    end
    it "responds to :title" do
      opportunity.respond_to?(:title).should be_true
    end
  end

  describe "self.available_filters" do
    it "has dictionary values that point to methods Opportunity responds to" do
      Opportunity.available_filters.each do |filter, method|
        Opportunity.respond_to?(method).should be_true
      end
    end
  end

  describe "self.filtered" do
    it "sends the available_filters dictionary value to Opportunity" do
      Opportunity.available_filters.each do |filter, method|
        Opportunity.should_receive(method)
        Opportunity.filtered(filter.to_s)
      end
    end
  end

  describe "scopes" do
    it "return ActiveRecord::Relation objects" do
      Opportunity.latest_created.class.should == ActiveRecord::Relation
      Opportunity.most_active.class.should == ActiveRecord::Relation
      Opportunity.recommended.class.should == ActiveRecord::Relation
      Opportunity.top_visited.class.should == ActiveRecord::Relation
    end

    context "latest_created" do
      it "returns opportunities with conversations most recently created" do
        opportunity1 = Factory.create(:opportunity, conversation: Factory.build(:conversation, created_at: Time.now - 2.day))
        opportunity2 = Factory.create(:opportunity, conversation: Factory.build(:conversation, created_at: Time.now - 1.day))
        Opportunity.latest_created.should == [opportunity2, opportunity1]
      end

      it "does not return opportunities with conversations that are excluded from `most_recent`" do
        opportunity1 = Factory.create(:opportunity, conversation: Factory.build(:conversation, exclude_from_most_recent: false))
        opportunity2 = Factory.create(:opportunity, conversation: Factory.build(:conversation, exclude_from_most_recent: true))
        Opportunity.latest_created.should == [opportunity1]
      end
    end

    context "most_active" do
      it "returns opportunities with the most contributions first" do
        conversation1 = Factory.create(:conversation_with_contribution)
        opportunity1 = Factory.create(:opportunity, conversation: conversation1)
        conversation2 = Factory.create(:conversation_with_contributions)
        opportunity2 = Factory.create(:opportunity, conversation: conversation2)
        Opportunity.most_active.should == [opportunity2, opportunity1]
      end

      it "returns opportunities with contributions in the last 60 days" do
        conversation1 = Factory.create(:conversation_with_contribution)
        contribution = conversation1.contributions.first
        contribution.created_at = Time.now - 61.days
        contribution.save
        opportunity1 = Factory.create(:opportunity, conversation: conversation1)
        conversation2 = Factory.create(:conversation_with_contribution)
        opportunity2 = Factory.create(:opportunity, conversation: conversation2)
        Opportunity.most_active.should == [opportunity2]
      end
    end

    context "recommended" do
      it "returns opportunities marked as recommended ordered by position" do
        conversation1 = Factory.create(:conversation, staff_pick: false)
        opportunity1 = Factory.create(:opportunity, conversation: conversation1)
        conversation2 = Factory.create(:conversation, staff_pick: true)
        opportunity2 = Factory.create(:opportunity, conversation: conversation2)
        conversation3 = Factory.create(:conversation, staff_pick: true)
        opportunity3 = Factory.create(:opportunity, conversation: conversation3)

        # needed to adjust for positions that change as objects are saved
        conversation2.position = 2
        conversation2.save
        conversation3.position = 1
        conversation3.save
        Opportunity.recommended.should == [opportunity3, opportunity2]
      end
    end

    context "top_visited" do
      it "returns opportunities ordered by most visits to their conversations" do
        conversation1 = Factory.create(:conversation, recent_visits: 10, last_visit_date: Time.now - 1.day)
        opportunity1 = Factory.create(:opportunity, conversation: conversation1)
        conversation2 = Factory.create(:conversation, recent_visits: 20, last_visit_date: Time.now - 1.day)
        opportunity2 = Factory.create(:opportunity, conversation: conversation2)
        Opportunity.top_visited.should == [opportunity2, opportunity1]
      end

      it "returns opportunities within last 30 days" do
        conversation1 = Factory.create(:conversation, recent_visits: 10, last_visit_date: Time.now - 1.day)
        opportunity1 = Factory.create(:opportunity, conversation: conversation1)
        conversation2 = Factory.create(:conversation, recent_visits: 20, last_visit_date: Time.now - 31.days)
        opportunity2 = Factory.create(:opportunity, conversation: conversation2)
        Opportunity.top_visited.should == [opportunity1]
      end
    end
  end
end