module Utilities
  module PersonUtilities

    private

    class Helper
      include ActionView::Helpers::TextHelper
    end

    public

    def self.pluralize(count, singular, plural = nil)
      @helper ||= Helper.new
      return @helper.pluralize(count, singular, plural)
    end

    def self.debug_print(text)
      puts text unless Rails.env.test?
    end

    def self.merge_account(to_person, from_person)
      unless to_person.is_a?(Person) and from_person.is_a?(Person) and to_person.id != from_person.id
        return false
      end

      debug_print 'beginning rake task'
      begin
        to_person.transaction do
          debug_print 'begin:   updating FROM account confirmed_at'
          from_person.confirmed_at = nil
          from_person.save!
          debug_print 'updated: ' + pluralize(1, 'record')
          debug_print 'end:     updating FROM account confirmed_at'

          debug_print 'begin:   updating contributions'
          updated_record_count = 0
          from_person.contributions.map do |contribution|
            contribution.owner = to_person.id
            contribution.save!
            updated_record_count += 1
          end
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating contributions'

          debug_print 'begin:   updating rating groups'
          # this will fail if the user has ratings for both accounts
          updated_record_count = 0
          RatingGroup.where('person_id = ?', from_person.id).map do |rating_group|
            rating_group.person_id = to_person.id
            rating_group.save!
            updated_record_count += 1
          end
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating rating groups'

          debug_print 'begin:   updating conversation owners'
          updated_record_count = 0
          Conversation.where('owner = ?', from_person.id).map do |conversation|
            conversation.owner = to_person.id
            conversation.save!
            updated_record_count += 1
          end
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating conversation owners'

          debug_print 'begin:   updating subscriptions'
          updated_record_count = 0
          # Make the TO account follow all the same conversations/issues as the FROM account
          Subscription.where(person_id: from_person.id).each do |subscription|
            Subscription.create_unless_exists(to_person, subscription.subscribable)
            updated_record_count += 1
          end
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating subscriptions'

          debug_print 'begin:   updating visits'
          updated_record_count = 0
          Visit.where('person_id = ?', from_person.id).map do |visit|
            visit.person_id = to_person.id
            visit.save!
            updated_record_count += 1
          end
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating visits'

          debug_print 'begin:   updating content_templates'
          updated_record_count = 0
          from_person.content_templates.map do |content_template|
            content_template.person_id = to_person.id
            content_template.save!
            updated_record_count += 1
          end
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating content_templates'

          debug_print 'begin:   updating authored content_items'
          updated_record_count = 0
          from_person.authored_content_items.map do |content_item|
            content_item.person_id = to_person.id
            content_item.save!
            updated_record_count += 1
          end
          
          debug_print 'begin:   updating content_items_people'
          to_person.content_items_people = from_person.content_items_people
          
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating content_items'

          debug_print 'begin:   updating managed_issue_pages'
          updated_record_count = 0
          from_person.managed_issue_pages.map do |managed_issue_page|
            managed_issue_page.person_id = to_person.id
            managed_issue_page.save!
            updated_record_count += 1
          end
          debug_print 'updated: ' + pluralize(updated_record_count, 'record')
          debug_print 'end:     updating managed_issue_pages'

        end # to_person.transaction

      rescue ActiveRecord::RecordInvalid => exception
        debug_print exception.message
        debug_print exception.backtrace.join("\n")
      end # begin

      debug_print 'ending rake task'
      return Person.find(from_person.id).confirmed_at.nil?
    end

  end
end
