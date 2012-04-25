require 'spec_helper'

describe Issue do

  def given_issue_with_nil_position
    issue = FactoryGirl.create(:issue)
    issue.position = nil
    issue.save
    issue
  end

  def given_3_issues
    @issue1 = FactoryGirl.create(:issue, {:created_at => (Time.now - 3.seconds), :updated_at => (Time.now - 3.seconds), :name => 'A first issue'})
    @issue2 = FactoryGirl.create(:issue, {:created_at => (Time.now - 2.seconds), :updated_at => (Time.now - 2.seconds), :name => 'Before I had a problem'})
    @issue3 = FactoryGirl.create(:issue, {:created_at => (Time.now - 1.second), :updated_at => (Time.now - 1.second), :name => 'Cat in the bag'})
    @person1 = FactoryGirl.create(:registered_user)
    @person2 = FactoryGirl.create(:registered_user)
    @person3 = FactoryGirl.create(:registered_user)

    conversation = FactoryGirl.create(:conversation, :issues => [@issue1, @issue2, @issue3])
    @contribution1 = FactoryGirl.create(:contribution, :conversation => conversation, :parent => nil, :issue => @issue1)
    @contribution2 = FactoryGirl.create(:contribution, :conversation => conversation, :parent => nil, :issue => @issue1)

    @contribution3 = FactoryGirl.create(:contribution, :conversation => conversation, :parent => nil, :issue => @issue2)
    @contribution4 = FactoryGirl.create(:contribution, :conversation => conversation, :parent => nil, :issue => @issue2)
    @contribution5 = FactoryGirl.create(:contribution, :conversation => conversation, :parent => nil, :issue => @issue2)

    @contribution6 = FactoryGirl.create(:contribution, :conversation => conversation, :parent => nil, :issue => @issue3)
  end

  def given_an_issue_with_conversations
    @person1 = FactoryGirl.create(:registered_user, :name => 'John D')
    @person2 = FactoryGirl.create(:registered_user, :name => 'Rick D')
    @conversation1 = FactoryGirl.create(:conversation, :person => @person1)
    @conversation2 = FactoryGirl.create(:conversation, :person => @person2)
    @conversation3 = FactoryGirl.create(:conversation, :person => @person2)
    @issue = FactoryGirl.create(:issue)
    @issue.conversations = [@conversation1, @conversation2, @conversation3]
    @issue.save
  end

  # TODO: I don't think this creates contributions correctly. Should only specify conversation OR issue
  def given_an_issue_with_contributions_and_participants
    @issue = FactoryGirl.create(:issue)
    @person1 = FactoryGirl.create(:registered_user)
    @person2 = FactoryGirl.create(:registered_user)
    @person3 = FactoryGirl.create(:registered_user)
    @conversation = FactoryGirl.create(:conversation)
    @conversation2 = FactoryGirl.create(:conversation)
    @contribution1 = FactoryGirl.create(:contribution, :person => @person1, :issue => @issue)
    @contribution2 = FactoryGirl.create(:contribution, :person => @person2, :conversation => @conversation, :issue => @issue)
    @contribution3 = FactoryGirl.create(:contribution, :person => @person2, :conversation => @conversation2, :issue => @issue)
  end

  def given_an_issue_with_contributions_and_conversations_and_page_visits
    @issue = FactoryGirl.create(:issue)
    @contribution = FactoryGirl.create(:contribution,:issue => @issue)
    @conversation = FactoryGirl.create(:conversation,:issues => [@issue])
    @issue.visits << FactoryGirl.create(:visit)
  end

  def given_2_issues_with_contributions_and_visits
    @issue1 = FactoryGirl.create(:issue)
    FactoryGirl.create(:contribution,:issue => @issue1)
    @issue1.visits << FactoryGirl.create(:visit)

    @issue2 = FactoryGirl.create(:issue)
    FactoryGirl.create(:contribution,:issue => @issue2)
    FactoryGirl.create(:contribution,:issue => @issue2)
    @issue2.visits << FactoryGirl.create(:visit)
    @issue2.visits << FactoryGirl.create(:visit)
  end

  def given_an_issue_with_conversations_and_comments
    @person = FactoryGirl.create(:registered_user)
    @issue = FactoryGirl.create(:issue)
    @other_issue = FactoryGirl.create(:issue)
    @other_conversation = FactoryGirl.create(:conversation)

    @conversation = FactoryGirl.create(:conversation,:issues => [@issue])
    @comment = FactoryGirl.create(:comment, :person => @person, :conversation => @conversation)
  end

  context "before_create" do
    it "sets the position to the maximum position + 1" do
      issue = FactoryGirl.create(:issue)
      issue.position.should == 0
      FactoryGirl.create(:issue)
      issue = FactoryGirl.create(:issue)
      issue.position.should == 2
    end
  end

  context "validations" do

    before(:each) do
      @issue = FactoryGirl.build(:issue)
    end

    it "validates a valid object" do
      @issue.should be_valid
    end

    it "requires a name" do
      @issue.name = nil
      @issue.should_not be_valid
    end

    it "requires the name to be at least five characters long" do
      @issue.name = '1234'
      @issue.should_not be_valid
      @issue.name = '12345'
      @issue.should be_valid
    end

    it "requires the name to be unique" do
      mi = FactoryGirl.create(:issue)
      @issue.name = mi.name
      @issue.should_not be_valid
    end

    it 'requires one topic to be assigned' do
      issue = FactoryGirl.build(:issue, topics: [])
      issue.should_not be_valid

      topic = FactoryGirl.build(:topic)
      issue.topics = [topic]
      issue.should be_valid
    end
  end

  context "associations" do
    context "has_many surveys" do
      def given_an_issue_with_many_surveys
        @issue = FactoryGirl.create(:issue)
        @survey1 = FactoryGirl.create(:survey,:surveyable_id => @issue.id, :surveyable_type => @issue.class.name)
        @survey2 = FactoryGirl.create(:survey,:surveyable_id => @issue.id, :surveyable_type => @issue.class.name)
      end
      it "should be correct" do
        Issue.reflect_on_association(:surveys).macro.should == :has_many
      end
      it "should be polymorphic as surveyable" do
        Issue.reflect_on_association(:surveys).options[:as].should == :surveyable
      end
      it "should correctly have many surveys" do
        given_an_issue_with_many_surveys
        @issue.surveys.should == [@survey1, @survey2]
      end
    end
    context "has_many votes" do
      def given_an_issue_with_many_votes
        @issue = FactoryGirl.create(:issue)
        @survey1 = FactoryGirl.create(:survey,:surveyable_id => @issue.id, :surveyable_type => @issue.class.name)
        @vote1 = FactoryGirl.create(:vote,:surveyable_id => @issue.id, :surveyable_type => @issue.class.name)
        @vote2 = FactoryGirl.create(:vote,:surveyable_id => @issue.id, :surveyable_type => @issue.class.name)
      end
      it "should be correct" do
        Issue.reflect_on_association(:votes).macro.should == :has_many
      end
      it "should be polymorphic as surveyable" do
        Issue.reflect_on_association(:votes).options[:as].should == :surveyable
      end
      it "should correctly have many votes" do
        given_an_issue_with_many_votes
        @issue.votes.should == [@vote1, @vote2]
      end
      it "should have 2 votes" do
        given_an_issue_with_many_votes
        @issue.votes.count.should == 2
      end
    end

    context "has_and_belongs_to_many topics" do
      def given_an_issue_with_topics
        @issue = FactoryGirl.create(:issue)
        @topic1 = FactoryGirl.create(:topic)
        @topic2 = FactoryGirl.create(:topic)
        @issue.topics = [@topic1, @topic2]
      end
      it "should be correct" do
        Issue.reflect_on_association(:topics).macro.should == :has_and_belongs_to_many
      end
      it "should correctly count the number of topics" do
        given_an_issue_with_topics
        @issue.topics.count.should == 2
      end
    end

  end

  context "scopes" do
    describe "published" do
      it "should query based on exclude_from_result = false" do
        Issue.published.to_sql.include?('`exclude_from_result` = 0').should be_true
      end
    end
    describe "standard_issue" do
      it "should query based on type is Issue" do
        Issue.standard_issue.to_sql.include?('`type` = \'Issue\'').should be_true
      end
    end
  end

  context "Top Issues" do

    it "should be determined by total # of contributions to an Issue + total # of page visits." do
      first_issue = FactoryGirl.create(:issue, name: "Issue 1")
      second_issue = FactoryGirl.create(:issue, name: "Issue 2")
      first_issue.stub_chain(:visits, :count) { 5 }
      second_issue.stub_chain(:visits, :count) { 3 }
      first_issue.stub_chain(:contributions, :count) { 7 }
      second_issue.stub_chain(:contributions, :count) { 5 }

      Issue.top_issues.should == [first_issue, second_issue]
    end

  end

  context "counters" do

    it "should have the correct count of contributions" do
      given_an_issue_with_contributions_and_conversations_and_page_visits
      @issue.contributions.count.should == 1
    end

    it "should have the correct count of conversations" do
      given_an_issue_with_contributions_and_conversations_and_page_visits
      @issue.conversations.count.should == 1
    end

    it "should have visit counts" do
      given_an_issue_with_contributions_and_conversations_and_page_visits
      @issue.visits.count.should == 1
    end

  end

  context "with participants" do

    it "should have the correct participants" do
      given_an_issue_with_contributions_and_participants
      @issue.participants.should == [@person1,@person2]
    end

    it "should have all issue participants when include is used" do
      given_an_issue_with_contributions_and_participants
      # i = Issue.find(@issue.id, :include => :participants)
      Issue.includes(:participants).find(@issue.id).participants.should == [@person1,@person2,@person2]
    end

    it "should have the correct number of participants" do
      given_an_issue_with_contributions_and_participants
      @issue.participants.count.should == 2
    end

  end

  context "Sort filter" do
    it "should sort by position ascending, id ascending by default" do
      @issue1 = FactoryGirl.create(:issue, :position => 2)
      @issue2 = FactoryGirl.create(:issue, :position => 0)
      @issue3 = FactoryGirl.create(:issue, :position => 1)
      Issue.sort(nil).collect(&:id).should == [@issue2, @issue3, @issue1].collect(&:id)
    end

    it "should sort issue by alphabetical" do
      given_3_issues
      Issue.sort('alphabetical').collect(&:id).should == [@issue1, @issue2, @issue3].collect(&:id)
    end

    it "should sort issue by date created" do
      given_3_issues
      Issue.sort('most_recent').collect(&:id).should == [@issue3, @issue2, @issue1].collect(&:id)
    end

    it "should sort issue by recently updated" do
      given_3_issues
      @issue1.touch
      Issue.sort('most_recent_update').first.should == @issue1
    end

    it "should sort by most active(# of participants and # of contributions)" do
      given_3_issues
      issues = Issue.most_active
      issues.collect(&:id).should == [@issue2.id,@issue1.id,@issue3.id]
    end

  end

  context "comments on issues" do

    it "should display the correct comments(contribution) that are attached to conversations arround that issues" do
      given_an_issue_with_conversations_and_comments
      @issue.conversation_comments.should == [@comment]
    end

    it "should not display other things on comments" do
      given_an_issue_with_conversations_and_comments
      @other_issue.conversation_comments.should == []
    end

  end

  context "self.assign_positions" do
    it "gives every item a position after sorting them by current position ascending, then id ascending" do
      issue1 = given_issue_with_nil_position
      issue2 = given_issue_with_nil_position
      issue3 = given_issue_with_nil_position
      issue4 = FactoryGirl.create(:issue, :position => 3)
      Issue.assign_positions
      issue4.reload.position.should == 0
      issue1.reload.position.should == 1
      issue2.reload.position.should == 2
      issue3.reload.position.should == 3
    end
  end

  context "self.set_position" do
    it "updates position on relevant issues with an issue position becomes smallest" do
      issue1 = FactoryGirl.create(:issue, :position => 0)
      issue2 = FactoryGirl.create(:issue, :position => 1)
      issue3 = FactoryGirl.create(:issue, :position => 2)
      # drag issue2 to be above issue1
      Issue.set_position(1, 0, nil)
      Issue.custom_order.should == [issue2, issue1, issue3]
    end

    it "updates position on relevant issues with an issue position becomes largest" do
      issue1 = FactoryGirl.create(:issue, :position => 0)
      issue2 = FactoryGirl.create(:issue, :position => 1)
      issue3 = FactoryGirl.create(:issue, :position => 2)
      # drag issue2 to be below issue3
      Issue.set_position(1, nil, 2)
      Issue.custom_order.should == [issue1, issue3, issue2]
    end

    it "updates position on relevant issues with an issue position increases" do
      issue1 = FactoryGirl.create(:issue, :position => 0)
      issue2 = FactoryGirl.create(:issue, :position => 1)
      issue3 = FactoryGirl.create(:issue, :position => 2)
      # drag issue1 to be below issue2
      Issue.set_position(0, 2, 1)
      Issue.custom_order.should == [issue2, issue1, issue3]
    end

    it "updates position on relevant issues with an issue position decreases" do
      issue1 = FactoryGirl.create(:issue, :position => 0)
      issue2 = FactoryGirl.create(:issue, :position => 1)
      issue3 = FactoryGirl.create(:issue, :position => 2)
      # drag issue3 to be below issue1
      Issue.set_position(2, 1, 0)
      Issue.custom_order.should == [issue1, issue3, issue2]
    end

  end

  context "conversation creators" do
    before(:each) do
      given_an_issue_with_conversations
    end
    it "should return the creators of conversation" do
      @issue.reload.conversations.count.should == 3
      @issue.conversation_creators_ids.include?(@person1.id).should be_true
      @issue.conversation_creators_ids.include?(@person2.id).should be_true
    end
  end

  context "community_user_ids" do
    before(:each) do
      @issue = FactoryGirl.create(:issue)
      @person = FactoryGirl.create(:registered_user)
      FactoryGirl.create(:issue_contribution, issue: @issue, person: @person)
    end
    it "should return an array of person ids" do
      @issue.community_user_ids.should == [@person.id]
    end
    it "should return same number of IDs as Person.find_confirmed_order_by_most_active with proxies" do
      FactoryGirl.create(:issue_contribution, issue: @issue, person: FactoryGirl.create(:proxy_person))
      community_user_ids = @issue.community_user_ids
      community_user_ids.length.should == Person.find_confirmed_order_by_most_active(community_user_ids).length
    end
  end

  context "most_newest_users" do
    before(:each) do
      @issue = FactoryGirl.create(:issue)
      @person = FactoryGirl.create(:registered_user)
      FactoryGirl.create(:issue_contribution, issue: @issue, person: @person)
    end
    it "should call Person.find_confirmed_order_by_recency" do
      Person.should_receive(:find_confirmed_order_by_recency).with([@person.id])
      @issue.most_newest_users
    end
  end

  context "order_by_alpha_users" do
    before(:each) do
      @issue = FactoryGirl.create(:issue)
      @person = FactoryGirl.create(:registered_user, :name => 'John Doe')
      FactoryGirl.create(:issue_contribution, issue: @issue, person: @person)
    end
    it "should call Person.find_confirmed_order_by_recency" do
      Person.should_receive(:find_confirmed_order_by_last_name).with(nil, [@person.id])
      @issue.order_by_alpha_users
    end
  end

  context "most active users" do
    it "includes 'participants' / users that add contributions from an issue page" do
      issue = FactoryGirl.create(:issue)
      person = FactoryGirl.create(:registered_user)
      FactoryGirl.create(:issue_contribution, issue: issue, person: person)
      ([person] - issue.most_active_users.to_a).size.should == 0
    end

    it "includes issue conversation creators" do
      given_an_issue_with_conversations
      ([@person1, @person2] - @issue.most_active_users.to_a).size.should == 0
    end

    it "includes issue conversation contributors" do
      issue = FactoryGirl.create(:issue)
      person1 = FactoryGirl.create(:registered_user)
      person2 = FactoryGirl.create(:registered_user)
      conversation1 = FactoryGirl.create(:conversation)
      conversation2 = FactoryGirl.create(:conversation)
      issue.conversations = [conversation1, conversation2]
      FactoryGirl.create(:contribution, :person => person1, :conversation => conversation1)
      FactoryGirl.create(:contribution, :person => person2, :conversation => conversation2)
      ([person1, person2] - issue.most_active_users.to_a).size.should == 0
    end

    it "includes issue conversation rating contributors" do
      issue = FactoryGirl.create(:issue_with_conversation)
      conversation = issue.conversations.first
      person1 = conversation.person
      person2 = FactoryGirl.create(:registered_user)
      contribution = FactoryGirl.create(:contribution, :person => person1, :conversation => conversation)
      rating_group = FactoryGirl.create(:rating_group, person: person2, contribution: contribution)
      ([person2] - issue.most_active_users.to_a).size.should == 0
    end

    it "includes returns no people if issue has no activity" do
      issue = FactoryGirl.create(:issue)
      issue.most_active_users.should == []
    end

    it "includes returns no people if even if there is activity on other issues" do
      given_an_issue_with_conversations
      issue = FactoryGirl.create(:issue)
      issue.most_active_users.should == []
    end
  end

  context "paperclip" do
    context "image" do
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

      it "should validate presence of attachemnt" do
        should validate_attachment_presence(:image)
      end
      
    end
    context "standard_banner_image" do
      it "should have db collumns for standard_banner_image" do
        should have_db_column(:standard_banner_image_file_name).of_type(:string)
        should have_db_column(:standard_banner_image_content_type).of_type(:string)
        should have_db_column(:standard_banner_image_file_size).of_type(:integer)
        
      end
      it "should only allow image attachements" do
        should validate_attachment_content_type(:standard_banner_image).
          allowing('image/bmp', 'image/gif', 'image/jpeg', 'image/png', 'image/pjpeg', 'image/x-png').
          rejecting('text/plain', 'text/xml')
      end
    end
  end
end
