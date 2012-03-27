require 'spec_helper'


describe Conversation do
  context "factories" do
    it 'should be valid' do
      Factory.build(:conversation).should be_valid
      Factory.create(:conversation).should be_valid
      Factory.build(:user_generated_conversation).should be_valid
      Factory.create(:user_generated_conversation).should be_valid
    end
  end

  context "Associations" do
    it { should have_many :contributions  }
    it { should have_attached_file :image }
    context "has_one survey" do
      it "should be correct" do
        Conversation.reflect_on_association(:survey).macro.should == :has_one
      end
      it "should be polymorphic as surveyable" do
        Conversation.reflect_on_association(:survey).options[:as].should == :surveyable
      end
    end
    context "has_and_belongs_to_many content_items" do
      def given_a_radio_show_with_conversations
        @radioshow = Factory.create(:radio_show)
        @conversation1 = Factory.create(:conversation)
        @conversation2 = Factory.create(:conversation)
        @radioshow.conversations = [@conversation1, @conversation2]
      end
      it "should be correct" do
        Conversation.reflect_on_association(:content_items).macro.should == :has_and_belongs_to_many
      end

      it "should have the correct conversations" do
        given_a_radio_show_with_conversations
        @conversation1.content_items.should == [@radioshow]
      end
    end
  end
  describe "a valid conversation" do
    before :each do
      @conversation = Factory.build(:conversation)
    end
    it "is invalid with no title" do
      @conversation.title = nil
      @conversation.should have_validation_error(:title)
    end
    it "is invalid with no zip code" do
      @conversation.zip_code = nil
      @conversation.should have_validation_error(:zip_code)
    end
    it "is invalid with no summary" do
      @conversation.summary = nil
      @conversation.should have_validation_error(:summary)
    end
    it "is invalid with no issues" do
      @conversation.issues = []
      @conversation.should have_validation_error(:issues)
    end
    it "is invalid with no owner" do
      @conversation.owner = nil
      @conversation.should have_validation_error(:owner)
    end
  end

  describe "when retrieving all of the issues associated with a conversation" do
    before(:each) do
      @normal_person = Factory.create(:normal_person)
    end
    it "should return issue" do
      conversation = Factory.create(:conversation)
      issue = Factory.create(:issue, :conversations=>[conversation])

      conversation.issues.reload.count.should == 2
      conversation.issues.should include issue
    end
  end

  describe "when creating a post for the conversation" do
    before(:each) do
      @comment = Factory.create(:comment)
      @person = Factory.create(:normal_person)
      @conversation = Factory.create(:conversation)
    end

  end
  context "about an issue" do

    it "should sort by the latest updated conversations" do
      issue = Factory.create(:issue, :name => 'A first issue')
      conversation1 = Factory.create(:conversation, {:issues => [issue], :updated_at => (Time.now - 3.seconds)})
      conversation2 = Factory.create(:conversation, {:issues => [issue], :updated_at => (Time.now - 2.seconds)})
      conversation3 = Factory.create(:conversation, {:issues => [issue], :updated_at => (Time.now - 1.second)})
      conversation4 = Factory.create(:conversation)
      conversation2.touch
      issue.conversations.latest_updated.should == [conversation2,conversation3,conversation1]
    end
  end

  describe "when creating several Conversations at once" do
    before(:each) do
      @conversation1 = Factory.create(:conversation)
      @conversation2 = Factory.create(:conversation)
      [@conversation1, @conversation2].each do |conv|
        3.times do
          Factory.create(:top_level_contribution, :conversation => conv)
        end
      end
    end
    it "does not corrupt lft/rgt bounds when earlier conversations are destroyed" do
      @conversation1.destroy

      #@conversation2.contributions.collect{|c| p "lft/rgt: #{c.lft} / #{c.rgt}"}
      @conversation2.contributions.collect(&:lft).uniq.size.should == @conversation2.contributions.size
      @conversation2.contributions.collect(&:rgt).uniq.size.should == @conversation2.contributions.size
    end
    it "destroyes contributions when conversation is destroyed" do
      contribution_ids = @conversation1.contributions.collect(&:id)
      @conversation1.destroy
      Contribution.where(:id => contribution_ids).count.should == 0
    end
    it "does not destroy contributions from other conversations when conversation is destroyed" do
      size = @conversation2.contributions.size
      @conversation1.destroy
      @conversation2.reload.contributions.size.should == size
    end
  end

  describe "when destroying a conversation" do
    before(:each) do
      @conversation = Factory.create(:conversation)
      @contribution = Factory.create(:contribution, :conversation => @conversation, :parent => nil)
      @top_level_contribution = Factory.create(:top_level_contribution, :conversation => @conversation)
      @nested_contribution = Factory.create(:contribution, :parent => @top_level_contribution, :conversation => @conversation)
    end

    it "destroys all nested contributions", :pending => 'broke during rails3 upgrade' do
      conversation_id = @conversation.id
      Contribution.find_all_by_conversation_id(conversation_id).count.should == 3
      @conversation.destroy
      Contribution.find_all_by_conversation_id(conversation_id).count.should == 0
    end

    it "destroys all subscriptions", :pending => 'broke during rails3 upgrade' do
      subscription = Factory.create(:conversation_subscription, :subscribable => @conversation)
      @conversation.destroy
      lambda{ Subscription.find(subscription.id) }.should raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "when filtering conversations" do
    Conversation.available_filter_names.each do |filter_name|
      it "filters by :#{filter_name} by grabbing the appropriate named scope and doesn't raise error" do
        Conversation.should_receive(Conversation.available_filters[filter_name.to_sym])
        lambda { Conversation.filtered(filter_name) }.should_not raise_error
      end
    end

    describe 'most_active filter' do
      it 'will not return conversations if they have no contributions' do
        Factory.create(:conversation, :contributions => [])
        Conversation.filtered('active').all.should be_empty
        Conversation.most_active.all.should be_empty
      end

      it 'will not return conversations if they are only of type TopLevelContribution' do
        conversation = Factory.create(:conversation)
        Factory.create(:top_level_contribution, :conversation => conversation)
        Conversation.filtered('active').all.should be_empty
        Conversation.most_active.all.should be_empty
      end

      it 'will return conversations with any contributions that are within 60 days' do
        conversation = Factory.create(:conversation, :contributions => [])
        top_level_contribution = Factory.create(:top_level_contribution, :conversation => conversation)
        Factory.create(:contribution, :parent => top_level_contribution, :conversation => conversation,
          :created_at => (Time.now - 59.days), :updated_at => (Time.now - 30.seconds))
        Conversation.filtered('active').all.first.should == conversation
        Conversation.most_active.all.first.should == conversation
      end

      it 'will not return conversations with contributions that are all older than 60 days' do
        conversation = Factory.create(:conversation, :contributions => [])
        top_level_contribution = Factory.create(:top_level_contribution, :conversation => conversation)
        Factory.create(:contribution, :parent => top_level_contribution, :conversation => conversation,
          :created_at => (Time.now - 61.days), :updated_at => (Time.now - 30.seconds))
        Conversation.filtered('active').all.should be_empty
        Conversation.most_active.all.should be_empty
      end

      it 'will return the conversation ordered by newest contribution descending if number of contributions is the same' do
        old_conversation = Factory.create(:conversation, :contributions => [])
        top_level_contribution = Factory.create(:top_level_contribution, :conversation => old_conversation)
        Factory.create(:contribution, :parent => top_level_contribution, :conversation => old_conversation,
          :created_at => (Time.now - 59.days), :updated_at => (Time.now - 30.seconds))

        new_conversation = Factory.create(:conversation, :contributions => [])
        top_level_contribution = Factory.create(:top_level_contribution, :conversation => new_conversation)
        Factory.create(:contribution, :parent => top_level_contribution, :conversation => new_conversation,
          :created_at => (Time.now - 1.days), :updated_at => (Time.now - 30.seconds))

        Conversation.filtered('active').all.first.should == new_conversation
        Conversation.most_active.all.first.should == new_conversation
        Conversation.filtered('active').all.last.should == old_conversation
        Conversation.most_active.all.last.should == old_conversation
      end
    end
  end

  describe "when creating a user-generated conversation" do
    before(:each) do
      @person = Factory.create(:normal_person)

      @contributions = {
        "0" => Factory.build(:comment, :owner => @person.id, :conversation => nil, :parent => nil).attributes,
        "1" => Factory.build(:question, :owner => @person.id, :conversation => nil, :parent => nil).attributes,
        "2" => Factory.build(:attached_file, :owner => @person.id, :conversation => nil, :parent => nil).attributes,
        "3" => Factory.build(:link, :owner => @person.id, :conversation => nil, :parent => nil).attributes,
        "4" => Factory.build(:embedded_snippet, :owner => @person.id, :conversation => nil, :parent => nil).attributes,
        "5" => Factory.build(:suggested_action, :owner => @person.id, :conversation => nil, :parent => nil).attributes,
        "6" => Factory.build(:embedly_contribution, :owner => @person.id, :conversation => nil, :parent => nil).attributes,
      }

      @conversation = Factory.build(:user_generated_conversation, :person => @person)
    end

    it "default user_generated_conversation factory should be valid" do
      @conversation.should be_valid
    end

    it "raises an error if conversation created without owner" do
      @conversation.owner = nil
      @conversation.should_not be_valid
    end

    it "filters out all invalid contributions (i.e. blank contributions from contribution form) before save" do
      @conversation.save
      @conversation.errors.should be_empty
      @conversation.contributions.size.should == 1
    end

    it "raises an error if conversation created with multiple contributions", :pending => 'broke during rails3 upgrade' do
      @contributions[1] = Factory.build(:question, :conversation => nil, :parent => nil).attributes
      @conversation = Factory.build(:user_generated_conversation,
                                    :person => @person,
                                    :contributions => [],
                                    :contributions_attributes => Marshal::load(Marshal.dump(@contributions)))
      @conversation.save
      @conversation.should have_validation_error(:contributions)
    end

    it "raises error if conversation created with no contributions" do
      @conversation.contributions = []
      @conversation.save
      @conversation.should have_validation_error(:contributions)
    end

    it "raises error if conversation created with no associated issues" do
      @conversation.issues = []
      @conversation.should have_validation_error(:issues)
    end

    it "automatically subscribes owner to conversation" do
      Subscription.delete_all
      @person.reload.subscriptions.length.should == 0
      @conversation.save
      @person.reload.subscriptions.length.should == 1
    end
  end

  describe "Conversation#Sort" do
    before(:each) do
      Conversation.delete_all
      @conversations = []
    end

    after(:each) do
      Conversation.delete_all
    end

    it "will return from order when there are no conversations" do
      Conversation.sort
    end

    it "will return from order when the positions shouldn't change" do
      @conversations << Factory.create(:conversation, { position: 0, staff_pick: true, title: 'Conversation 1' })
      @conversations << Factory.create(:conversation, { position: 1, staff_pick: true, title: 'Conversation 2' })
      @conversations << Factory.create(:conversation, { position: 2, staff_pick: false, title: 'Conversation 3' })

      Conversation.sort
      Conversation.find_by_id(@conversations[0].id).position.should == 0
      Conversation.find_by_id(@conversations[1].id).position.should == 1
      Conversation.find_by_id(@conversations[2].id).position.should == 2
    end

    it "will order the positions when they are out of order" do
      @conversations << Factory.create(:conversation, { position: 7, staff_pick: true, title: 'Conversation 1' })
      @conversations << Factory.create(:conversation, { position: 10, staff_pick: true, title: 'Conversation 2' })
      @conversations << Factory.create(:conversation, { position: 1, staff_pick: false, title: 'Conversation 3' })

      Conversation.sort
      Conversation.find_by_id(@conversations[0].id).position.should == 0
      Conversation.find_by_id(@conversations[1].id).position.should == 1
      Conversation.find_by_id(@conversations[2].id).position.should == 2
    end

    it "will order the positions when numbers are repeated" do
      @conversations << Factory.create(:conversation, { position: 10, staff_pick: true, title: 'Conversation 1' })
      @conversations << Factory.create(:conversation, { position: 10, staff_pick: true, title: 'Conversation 2' })
      @conversations << Factory.create(:conversation, { position: 10, staff_pick: false, title: 'Conversation 3' })

      Conversation.sort
      Conversation.find_by_id(@conversations[0].id).position.should == 0
      Conversation.find_by_id(@conversations[1].id).position.should == 1
      Conversation.find_by_id(@conversations[2].id).position.should == 2
    end
  end

  describe "Conversation#sort" do
    before(:each) do
      Conversation.delete_all
      @conversations = []
    end

    after(:each) do
      Conversation.delete_all
    end

    it "will sort correctly if there is one conversation with saff_pick on" do
      @conversations << Factory.create(:conversation, { position: 0, staff_pick: true, title: 'Conversation 1' })
      @conversations[0].sort
      Conversation.find_by_id(@conversations[0].id).position.should == 0
    end

    it "will sort correctly if there is one conversation with saff_pick off" do
      @conversations << Factory.create(:conversation, { position: 0, staff_pick: false, title: 'Conversation 1' })
      @conversations[0].sort
      Conversation.find_by_id(@conversations[0].id).position.should == 0
    end

    it "sets the postion to the next highest position of all featured conversations" do
      @conversations << Factory.create(:conversation, { position: 0, staff_pick: true, title: 'Conversation 1' })
      @conversations << Factory.create(:conversation, { position: 1, staff_pick: true, title: 'Conversation 2' })
      @conversations << Factory.create(:conversation, { position: 2, staff_pick: false, title: 'Conversation 3' })
      @conversations[0].sort
      Conversation.find_by_id(@conversations[0].id).position.should == 1
      Conversation.find_by_id(@conversations[1].id).position.should == 0
      Conversation.find_by_id(@conversations[2].id).position.should == 2
    end
  end

  describe "recommended" do
    before(:each) do
      @conversation_nr1 = Factory.create(:conversation)
      @conversation_nr2 = Factory.create(:conversation)
      @conversation_r1 = Factory.create(:conversation, :staff_pick => true)
      @conversation_r2 = Factory.create(:conversation, :staff_pick => true)
    end

    it "will select all recommanded conversations" do
      cr = Conversation.recommended
      cr.include?(@conversation_nr1).should be_false
      cr.include?(@conversation_nr2).should be_false
      cr.include?(@conversation_r1).should be_true
      cr.include?(@conversation_r2).should be_true
    end

    context "filted" do
      it "will select all recommanded conversations that are not filtered out" do
        cr = Conversation.random_recommended(1, @conversation_r1)
        cr.include?(@conversation_nr1).should be_false
        cr.include?(@conversation_nr2).should be_false
        cr.include?(@conversation_r1).should be_false
        cr.include?(@conversation_r2).should be_true
      end
    end
  end

  describe "random active" do
    before(:each) do
      @conversation_1 = Factory.create(:conversation, :updated_at => (Time.now - 1.seconds))
      @conversation_2 = Factory.create(:conversation, :updated_at => (Time.now - 2.seconds))
      @conversation_3 = Factory.create(:conversation, :updated_at => (Time.now - 3.seconds))
      @conversation_4 = Factory.create(:conversation, :updated_at => (Time.now - 4.seconds))
      @conversation_5 = Factory.create(:conversation, :updated_at => (Time.now - 5.seconds))

      Conversation.stub(:most_active).and_return([@conversation_1, @conversation_2, @conversation_3, @conversation_4, @conversation_5])
    end

    it "will select a random number of active conversations" do
      c_ra = Conversation.random_active(2, 4)

      c_ra_count = 0
      c_ra_count += 1 if c_ra.include?(@conversation_1)
      c_ra_count += 1 if c_ra.include?(@conversation_2)
      c_ra_count += 1 if c_ra.include?(@conversation_3)
      c_ra_count += 1 if c_ra.include?(@conversation_4)
      c_ra_count.should == 2

      c_ra.include?(@conversation5).should be_false
    end

  end

  describe "after saving a new conversation" do
    before(:each) do
      Conversation.delete_all
      Factory.create(:conversation, { title: 'Conversation 1' })
      Factory.create(:conversation, { title: 'Conversation 2' })
      Factory.create(:conversation, { title: 'Conversation 3' })
    end

    it "it will have the largest position" do
      conversation = Factory.create(:conversation, { title: 'Conversation 4' })
      conversation = Conversation.find_by_id(conversation.id)
      conversation.position.should == 3
    end

    it "automatically subscribes owner to conversation" do
      Subscription.delete_all
      person = Factory.create(:normal_person)
      conversation = Factory.build(:conversation, person: person)
      person.subscriptions.length.should == 0
      conversation.save
      person.reload.subscriptions.length.should == 1
    end
  end

  describe "conversations with exclude_from_most_recent" do
    before(:each) do
      # stub_amazon_s3_request
      @conversation = Factory.create(:conversation)
      @excluded_conversation = Factory.create(:conversation, { exclude_from_most_recent: true })
    end

    it "will not show in latest_created scope" do
      Conversation.latest_created.include?(@conversation).should be_true
      Conversation.latest_created.include?(@excluded_conversation).should be_false
    end
  end

  context "paperclip" do

    it "will have necessary db columns for paperclip" do
      should have_db_column(:image_file_name).of_type(:string)
      should have_db_column(:image_content_type).of_type(:string)
      should have_db_column(:image_file_size).of_type(:integer)
    end

    it "will only allow image attachments" do
      # allowed image mimetypes are based on what we have seen in production
      should validate_attachment_content_type(:image).
        allowing('image/bmp', 'image/gif', 'image/jpeg', 'image/png', 'image/pjpeg', 'image/x-png').
        rejecting('text/plain', 'text/xml')
    end

    it "will have an existing default image" do
      paperclip_default_file_exists?('original').should be_true
      Conversation.attachment_definitions[:image][:styles].each do |style, size|
        paperclip_default_file_exists?(style.to_s).should be_true
      end
    end

    def paperclip_default_file_exists?(style)
      default_url = Conversation.attachment_definitions[:image][:default_url].gsub(/\:style/, style)
      default_file = File.join(Rails.root, 'public', default_url)
      File.exist?(default_file)
    end
  end

end
