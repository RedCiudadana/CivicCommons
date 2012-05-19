module CivicCommonsDriver
  module Database
    def database
      Database
    end

    def self.delete_all_person
      Person.delete_all
    end

    def self.has_any?(type)
      !Topic.count.zero?
    end

    def self.has_any_topics?
      !Topic.count.zero?
    end

    def self.has_organization_matching?(org_detail)
      org = Organization.find_by_email(org_detail[:email])
      org.present?
    end

    def self.first_topic
      Topic.first
    end

    def self.latest_person
      # so that it doesn't select the subclass(e.g: Organization)
      Person.where(:type=> nil).last
    end

    def self.latest_blog_post
      ContentItem.blog_post.last
    end

    def self.latest_content_item_link
      content_item_link = ContentItemLink.last
      content_item_link.instance_eval do
        def container
          "[data-content-item-link-id='#{self.id}']"
        end
      end
      content_item_link
    end

    def self.latest_radio_show
      content_item = ContentItem.radio_show.last
      content_item.instance_eval do
        def container
          "[data-radio-show-id='#{self.id}']"
        end
      end
      content_item
    end

    def self.latest_topic
      topic = Topic.last
      topic.instance_eval do
        def removed_from? page
          page.has_no_css? container
        end
        def container
          "[data-topic-id='#{self.id}']"
        end
      end
      topic
    end

    def self.latest_blog_post_description
      ContentItemDescription.where(:content_type => 'BlogPost').last
    end

    def self.latest_radio_show_description
      ContentItemDescription.where(:content_type => 'RadioShow').last
    end

    def self.create_contribution attributes={}
      FactoryGirl.create :contribution, attributes
    end

    def self.create_conversation attributes={}
      FactoryGirl.create :conversation, attributes
    end

    def self.create_registered_user attributes={}
      FactoryGirl.create(:registered_user, attributes)
    end

    def self.create_topic(attributes={})
      FactoryGirl.create :topic, attributes
    end

    def self.has_a_topic_without_issues
      create_topic({:issues => []})
    end

    def self.has_an_organization(attributes={})
      FactoryGirl.create :organization, attributes
    end

    def self.create_issue(attributes= {})
      FactoryGirl.create :issue, attributes
    end

    def self.create_project(attributes= {})
      FactoryGirl.create :managed_issue, attributes
    end

    def self.create_blog_post(attributes = {})
      FactoryGirl.create :blog_post, attributes
    end

    def self.create_radio_show(attributes = {})
      FactoryGirl.create :radio_show, attributes
    end

    def self.create_email_restriction(attributes={})
      FactoryGirl.create :email_restriction, attributes
    end

    def self.destroy_all_content_items
      ContentItem.destroy_all
    end

    def self.destroy_all_topics
      Topic.destroy_all
    end

    class << self
      alias :has_a_blog_post :create_blog_post
      alias :has_a_radio_show :create_radio_show
      alias :has_a_conversation :create_conversation
      alias :has_an_issue :create_issue
      alias :has_a_topic :create_topic
    end

    def self.latest_issue
      IssuePresenter.new Issue.last
    end

    def self.issues
      Issue.all.map! { |i| IssuePresenter.new i }
    end

    def self.topics
      Topic.all
    end

    def self.has_any_issues?
      !Issue.all.empty?
    end

    def self.has_any_blog_posts?
      !ContentItem.blog_post.all.empty?
    end

    def self.has_any_radio_shows?
      !ContentItem.radio_show.all.empty?
    end

    def self.has_any_blog_post_descriptions?
      !ContentItemDescription.where(:content_type => 'BlogPost').empty?
    end

    def self.has_any_radio_show_descriptions?
      !ContentItemDescription.where(:content_type => 'RadioShow').empty?
    end

    def self.find_user(user)
      Person.find(user.id)
    end

    def self.conversation
      Conversation.last
    end

    def self.blog_post
      ContentItem.where(:content_type => 'BlogPost').last
    end

    def self.radio_show
      ContentItem.where(:content_type => 'RadioShow').last
    end
  end
end
