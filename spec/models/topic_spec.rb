require 'spec_helper'

describe Topic do
  describe "validation" do
    it "should validate presence of name" do
      should validate_presence_of(:name)
    end
    it "should validate uniqueness of name" do
      FactoryGirl.create(:topic)
      should validate_uniqueness_of(:name)
    end
  end
  describe "Associations" do
    context "has_many issues" do
      def given_a_topic_with_issues
        @topic = FactoryGirl.create(:topic)
        @issue1 = FactoryGirl.create(:issue)
        @issue2 = FactoryGirl.create(:issue)
        @topic.issues = [@issue1, @issue2]
      end
      it "should be correct" do
        Topic.reflect_on_association(:issues).macro.should == :has_many
      end
      it "should correctly count the number of topics" do
        given_a_topic_with_issues
        @topic.issues.count.should == 2
      end
    end

    context "has_many radioshows" do
      def given_a_topic_with_radioshows
        @topic = FactoryGirl.create(:topic)
        @radioshow1 = FactoryGirl.create(:radio_show)
        @radioshow2 = FactoryGirl.create(:radio_show)
        @topic.radioshows = [@radioshow1, @radioshow2]
      end
      it "should be correct" do
        Topic.reflect_on_association(:radioshows).macro.should == :has_many
      end
      it "should correctly count the number of topics" do
        given_a_topic_with_radioshows
        @topic.radioshows.count.should == 2
      end
    end

    context "has_many blogs" do
      def given_a_topic_with_blogs
        @topic = FactoryGirl.create(:topic)
        @blog1 = FactoryGirl.create(:blog_post)
        @blog2 = FactoryGirl.create(:blog_post)
        @topic.blogposts = [@blog1, @blog2]
      end
      it "should be correct" do
        Topic.reflect_on_association(:blogposts).macro.should == :has_many
      end
      it "should correctly count the number of blogs" do
        given_a_topic_with_blogs
        @topic.blogposts.count.should == 2
      end
    end

  end

  describe 'adding multiple topics' do
    context 'Issues' do
      it 'will not allow duplicates' do
        topic = FactoryGirl.create(:topic)
        issue = FactoryGirl.create(:issue)
        topic.issues = [issue, issue]
        topic.should be_true
        topic.issues.count.should == 1
      end
    end

    context 'RadioShows' do
      it 'will not allow duplicates' do
        topic = FactoryGirl.create(:topic)
        radioshow = FactoryGirl.create(:radio_show)
        topic.radioshows = [radioshow, radioshow]
        topic.should be_true
        topic.radioshows.count.should == 1
      end
    end
  end

  describe "For Sidebar" do
    context "Issues" do
      def given_topics_with_issues_for_sidebar
        @topic1 = FactoryGirl.create(:topic)
        @topic2 = FactoryGirl.create(:topic)
        @issue1 = FactoryGirl.create(:issue, :topics => [@topic1], :exclude_from_result=> true)
        @issue2 = FactoryGirl.create(:issue, :topics => [@topic1], :exclude_from_result=> false)
        @managed_issue1 = FactoryGirl.create(:managed_issue, :topics => [@topic1], :exclude_from_result=> false)
        @topic_result = Topic.including_public_issues.first
        Topic.including_public_issues.length.should == 1
      end
      it "should return topics that has an issue count of 1(one) or more" do
        given_topics_with_issues_for_sidebar
        @topic_result.issue_count.should == 1
      end
      it "should return only Issue type" do
        given_topics_with_issues_for_sidebar
        @topic_result.issues.first.type == 'Issue'
      end
      it "should only return issues where exclude_from_result = false" do
        @topic = FactoryGirl.create(:topic)
        @issue = FactoryGirl.create(:issue, :topics => [@topic], :exclude_from_result=> false)
        Topic.including_public_issues.length.should == 1
      end
      it "should not return anything when issues are exclude_from_result = true" do
        @topic = FactoryGirl.create(:topic)
        @issue = FactoryGirl.create(:issue, :topics => [@topic], :exclude_from_result=> true)
        Topic.including_public_issues.length.should == 0
      end
      it "should have issue_count as an additional select field" do
        given_topics_with_issues_for_sidebar
        @topic_result.respond_to?(:issue_count).should be_true
      end
    end

    context "RadioShows" do
      def given_topics_with_radioshows_for_sidebar
        topic = FactoryGirl.create(:topic)
        FactoryGirl.create(:topic)
        FactoryGirl.create(:radio_show, :topics => [topic])
        @topic_results = Topic.including_public_radioshows
      end

      it "should return topics that has a radioshow count of 1 (one) or more" do
        given_topics_with_radioshows_for_sidebar
        @topic_results.each do |topic|
          topic.content_item_count.should == 1
        end
      end

      it "should return only ContentItem type" do
        given_topics_with_radioshows_for_sidebar
        @topic_results.each do |topic|
          topic.radioshows.first.content_type == 'RadioShow'
        end
      end

      it "should have content_item_count as an additional select field" do
        given_topics_with_radioshows_for_sidebar
        @topic_results.each do |topic|
          topic.respond_to?(:content_item_count).should be_true
        end
      end
    end

    context "BlogPosts" do
      def given_topics_with_blogposts_for_sidebar
        topic = FactoryGirl.create(:topic)
        FactoryGirl.create(:topic)
        FactoryGirl.create(:blog_post, :topics => [topic])
        @topic_results = Topic.including_public_blogposts
      end

      it "should return topics that has a blogpost count of 1 (one) or more" do
        given_topics_with_blogposts_for_sidebar
        @topic_results.each do |topic|
          topic.content_item_count.should == 1
        end
      end

      it "should return only ContentItem type" do
        given_topics_with_blogposts_for_sidebar
        @topic_results.each do |topic|
          topic.blogposts.first.content_type == 'RadioShow'
        end
      end

      it "should have content_item_count as an additional select field" do
        given_topics_with_blogposts_for_sidebar
        @topic_results.each do |topic|
          topic.respond_to?(:content_item_count).should be_true
        end
      end
    end


  end
end