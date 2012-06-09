class DigestService

  attr_reader :digest_recipients,
              :digest_set,
              :updated_contributions,
              :updated_conversations,
              :updated_reflections,
              :votes_created_activities,
              :votes_ended_activities,
              :vote_response_activities,
              :new_petitions,
              :petition_signatures_activity

  def initialize
    @digest_set = { }
  end

  #TODO: Make a class for the digest data and return an array of that class
  #TODO: Use 'letter' param to segment the data set by first letter of last name
  #TODO: Optimize the data retrieval
  def generate_digest_set(letter = nil)
    get_digest_recipients
    get_updated_reflections
    get_vote_activities
    get_petition_related_activities
    get_updated_contributions
    get_updated_conversations
    get_recipient_subscriptions
    group_activities_by_conversation
  end

  def process_daily_digest(set = nil)

    # get the set of people receiving the digest email
    set = self.generate_digest_set if set.nil?
    # for each person
    set.each do |person, conversations|

      unless set[person].empty?
        # send the email
        Notifier.daily_digest(person, conversations).deliver
      end

    end

  end

  def get_digest_recipients
    @digest_recipients = Person.where(:daily_digest => true)
  end

  def time_range
    # set the time range for yesterday
    (Time.now.midnight - 1.day)..(Time.now.midnight - 1.second)
  end

  def get_updated_contributions
    # get the list of conversations that were updated yesterday
    @updated_contributions = Contribution.confirmed.includes(:conversation).order('conversation_id ASC, id ASC').where(created_at: time_range).where(top_level_contribution: false)
  end

  def get_updated_conversations
    # extract the individual conversation ids

    # Get conversations from updated contributions
    @updated_conversations = @updated_contributions.map { |c| c.conversation }
    # Get conversations from updated reflections
    @updated_conversations += @updated_reflections.map { |c| c.conversation }

    # Get conversations from votes created
    @updated_conversations += @votes_created_activities.map { |c| c.surveyable }
    # Get conversations from votes ended
    @updated_conversations += @votes_ended_activities.map { |c| c.surveyable }
    # Get conversations from votes responses
    @updated_conversations += @vote_response_activities.map { |c| c.survey.surveyable }

    ##### PETITION RELATED ACTIVITY #####
    # Get Conversations from Petitions Created
    @updated_conversations += @new_petitions.map {|p| p.conversation } if @new_petitions
    # Get Conversations from Petition Signatures
    @updated_conversations += @petition_signatures_activity.map {|sig| sig.petition_conversation } if @petition_signatures_activity

    @updated_conversations.uniq!
  end

  def get_updated_reflections
    @updated_reflections = Reflection.includes(:conversation).order('conversation_id ASC, id ASC').where(created_at: time_range)
  end

  def get_recipient_subscriptions
    # get the subscriptions for each person
    @digest_recipients.each do |person|

      subscriptions = person.subscriptions

      digest = []

      subscriptions.each do |sub|

        # is the subscription in the list of current conversations?
        if @updated_conversations.include? sub.subscribable
          digest << [sub.subscribable]
        end
      end

      @digest_set[person] = digest

    end

  end

  def get_votes_created_activities
    @votes_created_activities = Vote.where(surveyable_type: Conversation, created_at: time_range).order('surveyable_id ASC, id ASC').includes(:surveyable)
    @votes_created_activities.each do |record|
      #set this as an indicator for the mailer view
      record.daily_digest_type = 'created'
    end
  end

  def get_votes_ended_activities
    @votes_ended_activities = Vote.where(surveyable_type: Conversation, end_date: time_range.last.to_date).order('surveyable_id ASC, id ASC').includes(:surveyable)
    @votes_ended_activities.each do |record|
      #set this as an indicator for the mailer view
      record.daily_digest_type = 'ended'
    end

  end

  def get_vote_response_activities
    @vote_response_activities = SurveyResponse.joins(:survey).where(surveys: {surveyable_type: Conversation, type: Vote}, created_at: time_range).includes( survey: :surveyable)
  end

  def get_vote_activities
    get_votes_created_activities
    get_votes_ended_activities
    get_vote_response_activities
  end

  # Retrieves all the activity related to Petitions
  # 1) Petition Creation
  # 2) Petition Signatures
  def get_petition_related_activities
    get_new_petitions
    get_petition_signatures_activity
  end

  # Get All New Petitions
  def get_new_petitions
    @new_petitions = Petition.where(created_at: time_range).order('created_at ASC')
  end

  # Get Activity from Users Signing Petitions
  def get_petition_signatures_activity
    @petition_signatures_activity = PetitionSignature.where(created_at: time_range).order('created_at ASC')
  end

  # Gather All Activity by Conversation
  def group_activities_by_conversation
    @digest_set.each do |person, conversations_array|

      conversations_array.each do |conversation|

        contributions = @updated_contributions.select do |contribution|
          contribution.conversation == conversation.first
        end

        reflections = @updated_reflections.select do |reflection|
          reflection.conversation == conversation.first
        end

        votes_created = @votes_created_activities.select do |vote|
          vote.surveyable == conversation.first
        end

        votes_ended = @votes_ended_activities.select do |vote|
          vote.surveyable == conversation.first
        end

        vote_responses = @vote_response_activities.select do |vote_response|
          vote_response.survey.surveyable == conversation.first
        end

        petitions_created = @new_petitions.select do |petition|
          petition.conversation == conversation.first
        end

        petition_signatures = @petition_signatures_activity.select do |petition_signature|
          petition_signature.petition_conversation == conversation.first
        end

        items = (contributions + reflections + votes_created + votes_ended + vote_responses + petitions_created + petition_signatures)

        conversation << items
      end
    end
    return @digest_set

  end


  #TODO: Use 'letter' param to segment the data set by first letter of last name
  def self.send_digest(letter = nil, set = nil)
    digest = self.new
    digest.generate_digest_set(letter)
    digest.process_daily_digest(set)
  end

end
