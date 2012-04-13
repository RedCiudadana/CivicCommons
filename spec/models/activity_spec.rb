require 'spec_helper'

describe Activity do

  context "Validation" do

    let(:params) do
      FactoryGirl.attributes_for(:activity)
    end

    it "Requires item_id" do
      params.delete(:item_id)
      Activity.new(params).should_not be_valid
    end

    it "Requires item_type" do
      params.delete(:item_type)
      Activity.new(params).should_not be_valid
    end

    it "Requires item_created_at" do
      params.delete(:item_created_at)
      Activity.new(params).should_not be_valid
    end

    it "Validates the item exists" do
      params.delete(:item_created_at)
      Activity.new(params).should_not be_valid
    end

    it "Requires person_id" do
      params.delete(:person_id)
      Activity.new(params).should_not be_valid
    end

  end

  context "Creates new activity object from existing active record object" do

    it "Creates a new activity from valid conversation object" do
      obj = FactoryGirl.build(:conversation, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Conversation'
    end

    it "Creates a new activity from valid comment object" do
      obj = FactoryGirl.build(:comment, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Contribution'
    end

    it "Creates a new activity from valid question object" do
      obj = FactoryGirl.build(:question, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Contribution'
    end

    it "Creates a new activity from valid suggested action object" do
      obj = FactoryGirl.build(:suggested_action, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Contribution'
    end

    it "Creates a new activity from valid link object" do
      obj = FactoryGirl.build(:link, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Contribution'
    end

    it "Creates a new activity from valid answer object" do
      obj = FactoryGirl.build(:answer, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Contribution'
    end

    it "Creates a new activity from valid ebmedly object object" do
      obj = FactoryGirl.build(:embedly_contribution, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Contribution'
    end

    it "Creates a new activity from valid attached file object" do
      obj = FactoryGirl.build(:attached_file, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'Contribution'
    end

    it "Creates a new activity from valid rating group object" do
      obj = FactoryGirl.build(:rating_group, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'RatingGroup'
    end

    it "Creates a new activity from valid survey response object" do
      obj = FactoryGirl.build(:survey_response, id: 1, created_at: Time.now)
      a = Activity.new(obj)
      a.should be_valid
      a.item_type.should == 'SurveyResponse'
    end


    it "Does not create a new acivity on top level contribution" do
      obj = FactoryGirl.build(:top_level_contribution, id: 1, created_at: Time.now)
      Activity.new(obj).should_not be_valid
    end

    it "Does not create a new acivity on non supported active record type" do
      obj = FactoryGirl.build(:normal_person, id: 1, created_at: Time.now)
      Activity.new(obj).should_not be_valid
    end

  end

  context "Updating cache data when observed objects are saved" do

    it "updates contribution cache data when contribution is saved" do
      comment = FactoryGirl.create(:comment)
      item = Activity.new(comment)
      item.save
      comment.content = "Updated since last saved"
      comment.save
      Activity.update(comment)
      item.reload
      item.activity_cache.should match(/Updated since last save/)
    end

    it "updates conversation cache data when conversation is saved" do
      conversation = FactoryGirl.create(:conversation)
      item = Activity.new(conversation)
      item.save
      conversation.summary = "Updated since last saved"
      conversation.save
      Activity.update(conversation)
      item.reload
      item.activity_cache.should match(/Updated since last save/)
    end

  end

  context "Removing activity records" do

    let(:contrib) do
      FactoryGirl.create(:contribution)
    end

    let(:convo) do
      FactoryGirl.create(:conversation)
    end

    let(:rating_group) do
      FactoryGirl.create(:rating_group)
    end

    let(:survey) do
      FactoryGirl.create(:survey)
    end

    before(:each) do
      @item_count = 3
      @total_count = 12
      (1..@item_count).each do |i|
        FactoryGirl.create(:conversation_activity, item_id: convo.id)
        FactoryGirl.create(:contribution_activity, item_id: contrib.id)
        FactoryGirl.create(:rating_group_activity, item_id: rating_group.id)
        FactoryGirl.create(:survey_response_activity, item_id: survey.id)
      end
    end

    it "removes all activity records when one or more are found" do
      Activity.all.count.should == @total_count
      Activity.delete(convo)
      Activity.all.count.should == @total_count - @item_count
    end

    it "removed no activity objects when none are found" do
      Activity.all.count.should == @total_count
      Activity.destroy(convo)
      Activity.all.count.should == @total_count - @item_count
    end

    it "calls #delete_all for Acticity#delete" do
      Activity.should_receive(:delete_all).once
      Activity.delete(convo)
    end

    it "calls #destriy_all for Activity#destroy" do
      Activity.should_receive(:destroy_all).once
      Activity.destroy(convo)
    end

  end

  context "encoding activity cache data" do

    let(:conversation) { FactoryGirl.create(:conversation) }
    let(:comment) { FactoryGirl.create(:comment) }
    let(:rating_group) { FactoryGirl.create(:rating_group) }
    let(:vote_survey_response) {FactoryGirl.create(:vote_survey_response)}
    let(:petition) {FactoryGirl.create(:petition)}
    let(:petition_signature) {FactoryGirl.create(:petition_signature)}
    let(:reflection) {FactoryGirl.create(:reflection)}
    let(:reflection_comment) {FactoryGirl.create(:reflection_comment)}

    it "serializes a contribution object" do
      encoded_comment = Activity.encode(comment)
      encoded_comment.should be_an_instance_of String
      expect { JSON.parse(encoded_comment) }.should_not raise_exception
      encoded_comment.should match(/content/)
      encoded_comment.should match(/person/)
      encoded_comment.should match(/conversation/)
    end

    it "serializes a conversation object" do
      encoded_conversation = Activity.encode(conversation)
      encoded_conversation.should be_an_instance_of String
      expect { JSON.parse(encoded_conversation) }.should_not raise_exception
      encoded_conversation.should match(/summary/)
      encoded_conversation.should match(/person/)
    end

    it "serializes a rating group object" do
      encoded_rating_group = Activity.encode(rating_group)
      encoded_rating_group.should be_an_instance_of String
      expect { JSON.parse(encoded_rating_group) }.should_not raise_exception
      encoded_rating_group.should match(/conversation/)
      encoded_rating_group.should match(/person/)
      encoded_rating_group.should match(/ratings/)
    end

    it "serializes a survey response object" do
      encoded_survey_response = Activity.encode(vote_survey_response)
      encoded_survey_response.should be_an_instance_of String
      expect { JSON.parse(encoded_survey_response) }.should_not raise_exception
      encoded_survey_response.should match(/person/)
      encoded_survey_response.should match(/survey/)
      encoded_survey_response.should match(/survey.+type/)
    end
    
    it "serialize a petition object" do
      encoded_petition = Activity.encode(petition)
      encoded_petition.should be_an_instance_of String
      expect { JSON.parse(encoded_petition) }.should_not raise_exception
      encoded_petition.should match(/conversation/)
      encoded_petition.should match(/person/)
    end

    it "serialize a petition signature object" do
      encoded_petition_signature = Activity.encode(petition_signature)
      encoded_petition_signature.should be_an_instance_of String
      expect { JSON.parse(encoded_petition_signature) }.should_not raise_exception
      encoded_petition_signature.should match(/petition/)
      encoded_petition_signature.should match(/person/)
    end

    it "serialize a reflection object" do
      encoded_reflection = Activity.encode(reflection)
      encoded_reflection.should be_an_instance_of String
      expect { JSON.parse(encoded_reflection) }.should_not raise_exception
      encoded_reflection.should match(/conversation/)
      encoded_reflection.should match(/person/)
    end

    it "serialize a reflection comment object" do
      encoded_reflection_comment = Activity.encode(reflection_comment)
      encoded_reflection_comment.should be_an_instance_of String
      expect { JSON.parse(encoded_reflection_comment) }.should_not raise_exception
      encoded_reflection_comment.should match(/reflection/)
      encoded_reflection_comment.should match(/person/)
    end
    
  end

  context "decodes cache data into ActiveRecord object" do

    it "decodes a contribution object" do
      comment = FactoryGirl.create(:comment)
      encoded_comment = Activity.encode(comment)
      decoded_comment = Activity.decode(encoded_comment)
      decoded_comment.class == GenericObject
      decoded_comment.__class__ == 'Contribution'
      decoded_comment.id.should == comment.id
      decoded_comment.content.should == comment.content
    end

    it "decodes a conversation object" do
      conversation = FactoryGirl.create(:conversation)
      encoded_conversation = Activity.encode(conversation)
      decoded_conversation = Activity.decode(encoded_conversation)
      decoded_conversation.class == GenericObject
      decoded_conversation.__class__ == 'Conversation'
      decoded_conversation.summary.should == conversation.summary
      decoded_conversation.id.should == conversation.id
    end

    it "decodes a rating group object" do
      rating_group = FactoryGirl.create(:rating_group)
      encoded_rating_group = Activity.encode(rating_group)
      decoded_rating_group = Activity.decode(encoded_rating_group)
      decoded_rating_group.class == GenericObject
      decoded_rating_group.__class__ == 'RatingGroup'
      decoded_rating_group.conversation_id.should == rating_group.conversation_id
      decoded_rating_group.person_id.should == rating_group.person_id
    end

    it "decodes a survey repsonse object" do
      survey_response = FactoryGirl.create(:vote_survey_response)
      encoded_survey_response = Activity.encode(survey_response)
      decoded_survey_response = Activity.decode(encoded_survey_response)
      decoded_survey_response.class == GenericObject
      decoded_survey_response.__class__ == 'SurveyResponse'
      decoded_survey_response.survey_id.should == survey_response.survey_id
      decoded_survey_response.person_id.should == survey_response.person_id
    end
    it "decodes a petition object" do
      petition = FactoryGirl.create(:petition)
      encoded_petition = Activity.encode(petition)
      decoded_petition = Activity.decode(encoded_petition)
      decoded_petition.class == GenericObject
      decoded_petition.__class__ == 'Petition'
      decoded_petition.person_id.should == petition.person_id
      decoded_petition.conversation_id.should == petition.conversation_id
    end
    it "decodes a petition signature object" do
      petition_signature = FactoryGirl.create(:petition_signature)
      encoded_petition_signature = Activity.encode(petition_signature)
      decoded_petition_signature = Activity.decode(encoded_petition_signature)
      decoded_petition_signature.class == GenericObject
      decoded_petition_signature.__class__ == 'Petition'
      decoded_petition_signature.person_id.should == petition_signature.person_id
      decoded_petition_signature.petition_id.should == petition_signature.petition_id
    end
    it "decodes a reflection object" do
      reflection = FactoryGirl.create(:reflection)
      encoded_reflection = Activity.encode(reflection)
      decoded_reflection = Activity.decode(encoded_reflection)
      decoded_reflection.class == GenericObject
      decoded_reflection.__class__ == 'Reflection'
      decoded_reflection.owner.should == reflection.owner
      decoded_reflection.conversation_id.should == reflection.conversation_id
    end
    
    it "decodes a reflection comment object" do
      reflection_comment = FactoryGirl.create(:reflection_comment)
      encoded_reflection_comment = Activity.encode(reflection_comment)
      decoded_reflection_comment = Activity.decode(encoded_reflection_comment)
      decoded_reflection_comment.class == GenericObject
      decoded_reflection_comment.__class__ == 'ReflectionComment'
      decoded_reflection_comment.person_id.should == reflection_comment.person_id
      decoded_reflection_comment.reflection_id.should == reflection_comment.reflection_id
    end
  end

  context "Activity#exists?" do
    context "Checking if the Activity Exists or not" do

      before(:all) do
        ActiveRecord::Observer.enable_observers
      end

      after(:all) do
        ActiveRecord::Observer.disable_observers
      end

      let(:convo) do
        FactoryGirl.create(:conversation)
      end

      let(:rating_group) do
        FactoryGirl.create(:rating_group)
      end

      let(:invalid_type) do
        FactoryGirl.create(:normal_person)
      end

      it "should check existance based on item_id and item_type if it is a valid type" do
        @convo = convo
        Activity.count.should == 1
        Activity.exists?(@convo).should be_true
      end

      it "should use default 'exists?' method if it's not valid" do
        @rating_group = rating_group
        Activity.exists?(invalid_type).should be_false
      end
    end
  end

  describe "most recent activity items" do
    let(:contrib) do
      FactoryGirl.create(:contribution)
    end

    let(:convo) do
      FactoryGirl.create(:conversation)
    end

    let(:rating_group) do
      FactoryGirl.create(:rating_group)
    end

    before(:each) do
      FactoryGirl.create(:conversation_activity, item_id: convo.id, :item_created_at => 0.days.ago)
      FactoryGirl.create(:contribution_activity, item_id: contrib.id, :item_created_at => 1.days.ago)
      FactoryGirl.create(:rating_group_activity, item_id: rating_group.id, :item_created_at => 2.days.ago)
    end

    it "retrieves all the activity items" do
      Activity.most_recent_activity_items.should == [convo, contrib, rating_group]
    end

    it "retrieves a number of the activity items" do
      Activity.most_recent_activity_items(2).should == [convo, contrib]
    end

    it "retrieves a number of the activity items excluding items that no longer exist" do
      contrib.delete
      Activity.most_recent_activity_items(2).should == [convo]
    end
  end
end
