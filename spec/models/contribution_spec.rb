require 'spec_helper'

describe Contribution do

  context "factories" do
    it 'should be valid', :pending => 'broke during rails3 upgrade' do
      Factory.build(:contribution).should be_valid
      Factory.create(:contribution).should be_valid
      Factory.build(:top_level_contribution).should be_valid
      Factory.create(:top_level_contribution).should be_valid
      Factory.build(:unconfirmed_contribution).should be_valid
      Factory.create(:unconfirmed_contribution).should be_valid
      Factory.build(:contribution_without_parent).should be_valid
      Factory.create(:contribution_without_parent).should be_valid
      Factory.build(:issue_contribution).should be_valid
      Factory.create(:issue_contribution).should be_valid
      Factory.build(:comment_with_unique_content).should be_valid
      Factory.create(:comment_with_unique_content).should be_valid
      Factory.build(:question).should be_valid
      Factory.create(:question).should be_valid
      #Factory.build(:question_without_parent).should be_valid
      #Factory.create(:question_without_parent).should be_valid
      Factory.build(:answer).should be_valid
      Factory.create(:answer).should be_valid
      Factory.build(:attached_image).should be_valid
      Factory.create(:attached_image).should be_valid
      Factory.build(:attached_file).should be_valid
      Factory.create(:attached_file).should be_valid
      Factory.build(:link).should be_valid
      Factory.create(:link).should be_valid
      Factory.build(:embedded_snippet).should be_valid
      Factory.create(:embedded_snippet).should be_valid
      Factory.build(:comment).should be_valid
      Factory.create(:comment).should be_valid
      Factory.build(:embedly_contribution).should be_valid
      Factory.create(:embedly_contribution).should be_valid
    end
  end

  context "embedly" do

    before(:each) do
      @person = Factory.build(:registered_user)
      @contribution = Factory.attributes_for(:embedly_contribution)
      @contribution[:person] = @person
    end

    it "requires embedly_type when url given" do
      @contribution[:embedly_type] = nil
      Contribution.new(@contribution).should_not be_valid
    end

    it "requires embedly_code when url given" do
      @contribution[:embedly_code] = nil
      Contribution.new(@contribution).should_not be_valid
    end

  end

  context "attached file" do

    it "should return false when content type is not an image" do
      attached_file = Contribution.
        new(:attachment_content_type => "application/vnd.ms-excel")

      attached_file.is_image?.should_not be_nil
      attached_file.is_image? == false
    end

  end

  context "base_url" do

    let(:contribution) do
      Factory.build(:embedly_contribution)
    end

    it "returns blank when url is blank" do
      contribution.url = nil
      contribution.base_url.should be_blank
      contribution.url = ''
      contribution.base_url.should be_blank
    end

    it "returns the host valid base url when url is valid" do
      contribution.url = 'http://localhost:3000/issues/more-about-the-civic-commons'
      contribution.base_url.should == 'http://localhost:3000'
      contribution.url = 'http://www.youtube.com/watch?v=QCvYTijYDfE'
      contribution.base_url.should == 'http://www.youtube.com'
    end

  end

  describe "when destroyed" do
    it "should destroy rating groups associated with it" do
      @contribution = Factory.create(:contribution, {:created_at => Time.now - 25.minutes})

      rating_group = Factory.create(:rating_group, contribution: @contribution)
      @contribution.destroy

      lambda {RatingGroup.find(rating_group.id)}.should raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "when creating a TopLevelContribution for a conversation" do

    before(:each) do
      @top_level_contribution = Factory.build(:top_level_contribution)
      @top_level_contribution.run_callbacks(:save)
    end

    it "sets confirmed = true by default" do
      @top_level_contribution.confirmed.should be_true
    end

  end

  describe "when confirming contributions" do

    before(:each) do
      @contribution = Factory.create(:unconfirmed_contribution)
    end

    it "omits unconfirmed contributions (those only previewed but never confirmed) in confirmed scope" do
      contributions = Contribution.confirmed.all
      contributions.should_not include @contribution
    end

    it "returns only unconfirmed contributions for unconfirmed scope" do
      contributions = Contribution.unconfirmed.all
      contributions.should include @contribution
    end

    it "successfully sets :confirmed to true with .confirm! method and saves to database" do
      @contribution.confirm!
      @contribution.confirmed.should be_true
      contribution = Contribution.confirmed.find(@contribution.id)
      contribution.confirmed.should be_true
    end

  end

  describe "when editing and deleting confirmed contributions" do

    before(:each) do
      @person = Factory.create(:registered_user)
      @old_contribution = Factory.create(:contribution, {:created_at => Time.now - 35.minutes, :person => @person})
      @new_contribution = Factory.create(:contribution, {:created_at => Time.now - 5.minutes, :person => @person})
      @new_params = {:contribution => { 'content' => "Some new comment", 'url' => "http://www.youtube.com/watch?v=djtNtt8jDW4" } }
    end

    context "as the contributing user" do

      it "allows deletion by the user within 30 minutes of creation" do
        @new_contribution.should_receive(:destroy)
        @new_contribution.destroy_by_user(@person)
      end

      it "disallows deletion by the user if older than 30 minutes" do
        @old_contribution.should_not_receive(:destroy)
        @old_contribution.destroy_by_user(@person)
        @old_contribution.should have_generic_error(:base, /Contributions cannot be deleted if they are older than 30 minutes or have any responses./)
      end

      it "disallows deletion by the user if anyone has rated or replied to the contribution" do
        rating_group = Factory.create(:rating_group, contribution: @new_contribution)
        @new_contribution.should_not_receive(:destroy)
        @new_contribution.destroy_by_user(@person)
        @new_contribution.should have_generic_error(:base, /Contributions cannot be deleted if they are older than 30 minutes or have any responses./)
      end

      it "allows editing by the user within 30 minutes of creation" do
        @new_contribution.update_attributes_by_user(@new_params, @person)
        @new_contribution.content.should == @new_params[:contribution]['content']
        @new_contribution.url.should == @new_params[:contribution]['url']
      end

      it "disallows editing by the user if older than 30 minutes" do
        @old_contribution.update_attributes_by_user(@new_params, @person)
        @new_contribution.content.should_not == @new_params[:contribution]['content']
        @new_contribution.url.should_not == @new_params[:contribution]['url']
        @old_contribution.should have_generic_error(:base, /Contributions cannot be edited if they are older than 30 minutes or have any responses./)
      end

      it "disallows editing by the user if anyone has rated or replied to the contribution" do
        rating_group = Factory.create(:rating_group, contribution: @new_contribution)
        @new_contribution.should_not_receive(:update)
        @new_contribution.update_attributes_by_user(@new_params, @person)
        @new_contribution.should have_generic_error(:base, /Contributions cannot be edited if they are older than 30 minutes or have any responses./)
      end

      it "only updates updateable parameters" do
        @non_updateable_params = {:parent_id => @new_contribution.id + 1}
        @new_contribution.update_attributes_by_user(@new_params.merge(@non_updateable_params), @person)
        @new_params[:contribution].each_pair do |key, value|
          @new_contribution.send(key.to_s).should == value
        end
        @non_updateable_params.each_pair do |key, value|
          @new_contribution.send(key.to_s).should_not == value
        end
      end
    end

    context "as an admin user" do

      before(:each) do
        @admin_person = Factory.create(:admin_person)
      end

      it "allows deletion by an admin at any time" do
        @old_contribution.should_receive(:destroy)
        @old_contribution.destroy_by_user(@admin_person)
      end

      it "allows editing by an admin at any time" do
        @old_contribution.update_attributes_by_user(@new_params, @admin_person)
        @old_contribution.content.should == @new_params[:contribution]['content']
        @old_contribution.url.should == @new_params[:contribution]['url']
      end

    end

    context "as another user" do

      before(:each) do
        @other_person = Factory.create(:registered_user)
      end

      it "disallows deletion by another user" do
        @new_contribution.should_not_receive(:destroy)
        @new_contribution.destroy_by_user(@other_person)
        @new_contribution.should have_generic_error(:base, /Contributions cannot be deleted if they are older than 30 minutes or have any responses./)
      end

      it "disallows deletion by another user" do
        @new_contribution.should_not_receive(:destroy)
        @new_contribution.destroy_by_user(@other_person)
        @new_contribution.should have_generic_error(:base, /Contributions cannot be deleted if they are older than 30 minutes or have any responses./)
      end

      it "disallows editing by another user" do
        @new_contribution.should_not_receive(:update)
        @new_contribution.update_attributes_by_user(@new_params, @other_person)
        @new_contribution.should have_generic_error(:base, /Contributions cannot be edited if they are older than 30 minutes or have any responses./)
      end

    end

    it "#editable_by?(user) returns false for a logged-out user" do
      @new_contribution.editable_by?(nil).should be_false
    end

  end

  describe "moderating content" do

    before :each do
      @reason = { :moderation_reason => "violates tos" }
      @person = Factory.create(:admin_person)
    end

    it "sets the reason for moderation in the content" do
      contribution = Factory.create(:comment)
      reason = { :contribution => @reason }
      contribution.moderate_content(reason, @person).should be_true
      contribution.content.should match(reason[:contribution][:moderation_reason])
    end

    it "sets the contribution type to Comment" do
      contribution = Factory.create(:question)
      reason = { :contribution => @reason }
      contribution.moderate_content(reason, @person).should be_true
    end

    it "clears attachments", :pending => 'broke during rails3 upgrade' do
      contribution = Factory.create(:attached_file)
      reason = { :contribution => @reason }
      contribution.moderate_content(reason, @person).should be_true
      contribution.attachment.should_not exist
    end

    it "clears embedly_content", :pending => 'broke during rails3 upgrade' do
      contribution = Factory.create(:embedly_contribution)
      reason = { :contribution => @reason }
      contribution.moderate_content(reason, @person).should be_true
      contribution.embedly_code.should be_nil
      contribution.embedly_type.should be_nil
    end

    it "clears title and description", :pending => 'broke during rails3 upgrade' do
      contribution = Factory.create(:embedly_contribution)
      reason = { :contribution => @reason }
      contribution.moderate_content(reason, @person).should be_true
      contribution.title.should be_nil
      contribution.description.should be_nil
    end

  end

  describe "when updating AttachedFile" do

    before(:each) do
      @person = Factory.create(:normal_person)
      @attached_file = Factory.create(:attached_file, {:person => @person})
    end

    it "does nothing to the file attachment if left blank" do
      #@attached_file.should_not_receive(:save_attached_files) # apparently #save_attached_files gets called on every save whether the attachment is updated or not
      old_attachment_name = @attached_file.attachment_file_name
      @attached_file.update_attributes_by_user({:attachment => ''}, @person)
      @attached_file.attachment_file_name.should == old_attachment_name
    end

    it "updates the attached file if file is specified" do
      @attached_file.should_receive(:save_attached_files)
      @attached_file.update_attributes_by_user({contribution: {:attachment => File.new(Rails.root + 'test/fixtures/images/test_image2.jpg')}}, @person)
      @attached_file.attachment_file_name.should == "test_image2.jpg"
    end

  end

  describe "when updating a Link", :pending => 'broke during rails3 upgrade' do

    before(:each) do
      @person = Factory.create(:normal_person)
      @link = Factory.create(:link, {:person => @person})
    end

    it "does nothing to the URL if left blank" do
      old_url = @link.url
      @link.update_attributes_by_user({:url => ''}, @person)
      @link.url.should == old_url
    end

    it "updates the URL if new URL is specified" do
      new_url = 'http://maps.google.com/maps?f=q&source=s_q&hl=en&q=1360+East+Ninth+Street%2C+Suite+210%2C+Cleveland%2C+OH+44114&sll=41.510184%2C-81.690967&sspn=0.008243%2C0.019205&ie=UTF8&hnear=1360+E+9th+St+%23210%2C+Cleveland%2C+Cuyahoga%2C+Ohio+44114&ll=41.503451%2C-81.690087&spn=0.008244%2C0.019205&t=h&z=16'
      @link.update_attributes_by_user({ contribution: {:url => new_url} }, @person)
      @link.url.should == new_url
    end

  end

  describe "when deleting old unconfirmed contributions" do

    before(:each) do
      @old_unconfirmed_contribution = Factory.create(:comment, {:created_at => Time.now - 3.days, :override_confirmed => false})
      @new_unconfirmed_contribution = Factory.create(:comment, {:created_at => Time.now, :override_confirmed => false})
      @old_confirmed_contribution = Factory.create(:comment, {:created_at => Time.now - 3.days})
      @new_confirmed_contribution = Factory.create(:comment, {:created_at => Time.now})
      @count = Contribution.delete_old_and_unconfirmed
      @remaining_contributions = Contribution.all
    end

    it "returns correct number of deleted contributions" do
      @count.should == 1
    end

    it "deletes old unconfirmed contributions" do
      @remaining_contributions.should_not include @old_unconfirmed_contribution
    end

    it "does not delete unconfirmed contributions newer than 1 day" do
      @remaining_contributions.should include @new_unconfirmed_contribution
    end

    it "does not delete confirmed contributions" do
      @remaining_contributions.should include @old_confirmed_contribution
      @remaining_contributions.should include @new_confirmed_contribution
    end

  end

  describe "when creating for a conversation" do

    before(:each) do
      @conversation = Factory.create(:conversation)
      @person = Factory.create(:normal_person)
      @top_level_contribution = Factory.create(:top_level_contribution,{:conversation=>@conversation})
      @contribution = Factory.build(:unconfirmed_contribution, {
        :person => @person,
        :conversation => @conversation,
        :parent => @top_level_contribution
      } )
    end

    context "and there is a validation error" do

      it "should return a contribution with an error" do
        @contribution.content = nil
        @contribution.should have_validation_error(:content)
      end

    end

    describe "when it is saved for preview" do

      before(:each) do
        # @contribution.run_callbacks(:save) # this does not work with awesome_nested_set apparently
        @contribution.save!
      end

      it "saves with :confirmed set to false" do
        @contribution.confirmed.should be_false
      end

      it "should set the passed in user as the owner" do
        @contribution.person.should == @person
      end

      it "should set the item to the conversation" do
        @contribution.item.should == @conversation
      end

    end

    describe "and using node level contribution methods" do

      before(:each) do
        @attributes = Factory.attributes_for(:unconfirmed_contribution,
                                             :conversation => @contribution.conversation,
                                             :parent_id => @contribution.parent_id)
      end

      context "when using Contribution.new_node" do

        it "sets up a valid contribution but doesn't save it to the db", :pending => 'broke during rails3 upgrade' do
          contribution = Contribution.new_node(@attributes, @person)
          contribution.valid?.should be_true
          contribution.new_record?.should be_true
        end

      end

      context "when using Contribution.create_node" do

        it "sets up and creates a valid contribution saved to the db", :pending => 'broke during rails3 upgrade' do
          contribution = Contribution.create_node(@attributes, @person)
          contribution.valid?.should be_true
          contribution.confirmed.should be_false
          contribution.new_record?.should be_false
        end

      end

      context "when using Contribution.create_confirmed_node_level_contribution" do

        it "sets up and creates a valid confirmed contribution saved to the db", :pending => 'broke during rails3 upgrade' do
          contribution = Contribution.create_node(@attributes, @person, true)
          contribution.valid?.should be_true
          contribution.confirmed.should be_true
          contribution.new_record?.should be_false
        end

      end

      describe "dealing with preview functionality" do

        before(:each) do
          @contribution.save!
        end

        context "when using Contribution.find_or_create_node" do

          it "finds and returns unconfirmed contribution for user/parent combination, if it exists, but with new content" do
            new_comment = "This is a different comment"
            attributes = @attributes.merge(:content => new_comment)
            new_contribution = Contribution.update_or_create_node(attributes, @person)
            new_contribution.id.should == @contribution.id
            new_contribution.content.should == new_comment
          end

          it "creates and returns a new contribution if no unconfirmed contribution exists for user/parent combination" do
            attributes = @attributes.merge(:parent_id => (@contribution.parent_id + 1))
            new_contribution = Contribution.update_or_create_node(attributes, @person)
            new_contribution.id.should_not == @contribution.id
          end

        end

      end

      describe "and it is saved successfully" do

        before(:each) do
          @contribution.override_confirmed = true
          @contribution.save!
        end

        it "should add the contribution to a conversation" do
          @conversation.contributions.count.should == 2
          @conversation.contributions.should include @contribution
        end

      end

    end

  end

  describe "when creating a contribution for an issue" do

    before(:each) do
      @issue = Factory.create(:issue)
      @mock_person = Factory.create(:normal_person)
    end

    it "should set the item to the issue" do
      contribution = Contribution.create({:issue=>@issue, :person=>@mock_person, :content=>"Hello World"})
      contribution.item.should == @issue
    end

  end

  describe "validating a contribution" do

    it "should require an issue or a contributiion" do
      person = Factory.create(:normal_person)
      contribution = Contribution.create_node({:content => "Foo Bar"}, person)
      contribution.errors.count.should == 1
    end

    context "when a url is provided" do
      it "rejects invalid urls" do
        person = Factory.create(:normal_person)
        contribution = Contribution.create_node({:url=>'asdf'}, person)
        contribution.should have_validation_error :url
      end
    end

  end

  describe "validating a contribution for an issue" do

    before(:each) do
      @issue = Factory.create(:issue)
      @person = Factory.create(:normal_person)
    end

    it "should be valid when creating a Comment" do
      contribution = Contribution.create_node({:issue_id => @issue.id, :content => "Foo Bar"}, @person)
      contribution.valid?.should be_true
    end

    it "should not be valid without a person" do
      contribution = Contribution.create_node({:issue_id => @issue.id, :content => "Foo Bar"}, nil)
      contribution.valid?.should be_false
    end

  end

  describe "when deleting contributions of" do

    def given_a_contribution(type)
      @person = Factory.create(:normal_person)
      @other_person = Factory.create(:normal_person)
      @admin_person = Factory.create(:admin_person)
      @contribution = Factory.create(type, {:person => @person})
    end

    describe "suggested action" do

      it "should be able to be deleted by admin" do
        given_a_contribution(:suggested_action)
        @contribution.destroy_by_user(@admin_person).should be_true
      end

      it "should be able to be deleted by the creator" do
        given_a_contribution(:suggested_action)
        @contribution.destroy_by_user(@person).should be_true
      end

      it "should not be able to be deleted by other person" do
        given_a_contribution(:suggested_action)
        @contribution.destroy_by_user(@other_person).should be_false
      end

    end

    describe "EmbeddedSnippet" do

      it "should be able to be deleted by admin", :pending => 'broke during rails3 upgrade' do
        given_a_contribution(:embedded_snippet)
        @contribution.destroy_by_user(@admin_person).should be_true
      end

      it "should be able to be deleted by the creator", :pending => 'broke during rails3 upgrade' do
        given_a_contribution(:embedded_snippet)
        @contribution.destroy_by_user(@person).should be_true
      end

      it "should not be able to be deleted by other person", :pending => 'broke during rails3 upgrade' do
        given_a_contribution(:embedded_snippet)
        @contribution.destroy_by_user(@other_person).should be_false
      end

    end

    describe "AttachedFile" do

      it "should be able to be deleted by admin" do
        given_a_contribution(:attached_file)
        @contribution.destroy_by_user(@admin_person).should be_true
      end

      it "should be able to be deleted by the creator" do
        given_a_contribution(:attached_file)
        @contribution.destroy_by_user(@person).should be_true
      end

      it "should not be able to be deleted by other person" do
        given_a_contribution(:attached_file)
        @contribution.destroy_by_user(@other_person).should be_false
      end

    end

    describe "Link" do

      it "should be able to be deleted by admin", :pending => 'broke during rails3 upgrade' do
        given_a_contribution(:link)
        @contribution.destroy_by_user(@admin_person).should be_true
      end

      it "should be able to be deleted by the creator", :pending => 'broke during rails3 upgrade' do
        given_a_contribution(:link)
        @contribution.destroy_by_user(@person).should be_true
      end

      it "should not be able to be deleted by other person", :pending => 'broke during rails3 upgrade' do
        given_a_contribution(:link)
        @contribution.destroy_by_user(@other_person).should be_false
      end

    end

  end

  context "Existing contribution, conversation, and issue" do

    let(:contribution) {Contribution.new(content: "This is a contribution")}
    let(:conversation) {Factory.create(:conversation, title: "I'm a conversation")}
    let(:issue)        {Factory.create(:issue, name: "I'm an Issue")}

    describe "Contribution#item_id" do

      it "Retuns the id of the issue" do
        issue.contributions << contribution
        contribution.item.id.should == issue.id
      end

      it "Returns the id of the conversation" do
        conversation.contributions << contribution
        contribution.item.id.should == conversation.id
      end

    end

  end

  context "paperclip" do
    it "will have necessary db columns for paperclip" do
      should have_db_column(:attachment_file_name).of_type(:string)
      should have_db_column(:attachment_content_type).of_type(:string)
      should have_db_column(:attachment_file_size).of_type(:integer)
    end
  end

end
