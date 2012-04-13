require 'spec_helper'

describe ActivityObserver do

  before :all do
    ActiveRecord::Observer.enable_observers
  end

  after :all do
    ActiveRecord::Observer.disable_observers
  end

  before :each do
    AvatarService.stub(:update_person).and_return(true)
  end
  
  def given_a_user_have_voted
    @person = FactoryGirl.create(:registered_user)
    @survey = FactoryGirl.create(:vote)
    @survey_option1 = FactoryGirl.create(:survey_option,:survey_id => @survey.id, :position => 1)
    @presenter = VoteResponsePresenter.new(:person_id => @person.id,
      :survey_id => @survey.id, 
      :selected_option_1_id => 11, 
      :selected_option_2_id => 22)
    @presenter.save
  end

  context "On create" do

    it 'creates a new activity record when a conversation is created' do
      conversation = FactoryGirl.create(:conversation)
      a = Activity.last
      a.item_id.should == conversation.id
      a.item_type.should == 'Conversation'
      a.activity_cache.should_not be_nil
    end

    it 'creates a new activity record when a rating group is created' do
      rating_group = FactoryGirl.create(:rating_group)
      a = Activity.last
      a.item_id.should == rating_group.id
      a.item_type.should == 'RatingGroup'
      a.activity_cache.should_not be_nil
    end
    
    it "creates a new activity record when someone have voted(A survey_response has been created)" do
      given_a_user_have_voted
      a = Activity.last
      a.item_id.should == @presenter.id
      a.item_type.should == 'SurveyResponse'
      a.activity_cache.should_not be_nil
    end
    
    it 'creates a new activity record when a Petition is created' do
      petition = FactoryGirl.create(:petition)
      a = Activity.last
      a.item_id.should == petition.id
      a.item_type.should == 'Petition'
      a.activity_cache.should_not be_nil
    end
    
    it 'creates a new activity record when a PetitionSignature is created' do
      petition_signature = FactoryGirl.create(:petition_signature)
      a = Activity.last
      a.item_id.should == petition_signature.id
      a.item_type.should == 'PetitionSignature'
      a.activity_cache.should_not be_nil
    end

    it 'creates a new activity record when a Reflection is created' do
      reflection = FactoryGirl.create(:reflection)
      a = Activity.last
      a.item_id.should == reflection.id
      a.item_type.should == 'Reflection'
      a.activity_cache.should_not be_nil
    end
    
    it 'creates a new activity record when a Reflection Comment is created' do
      reflection_comment = FactoryGirl.create(:reflection_comment)
      a = Activity.last
      a.item_id.should == reflection_comment.id
      a.item_type.should == 'ReflectionComment'
      a.activity_cache.should_not be_nil
    end
  end

  context "after saving" do

    it 'creates a new activity record when a contribution is confirmed' do
      conversation = FactoryGirl.create(:conversation)
      contribution = FactoryGirl.create(:contribution, :conversation => conversation)
      contribution = FactoryGirl.create(:contribution, :conversation => conversation)
      a = Activity.where(item_type: 'Contribution', item_id: contribution.id).first
      a.item_id.should == contribution.id
      a.item_type.should == 'Contribution'
      a.activity_cache.should_not be_nil
    end

    it 'does not create a contribution activity record when contribution is part of conversation creation' do
      contribution = FactoryGirl.create(:top_level_contribution)
      Activity.where(item_id: contribution.id, item_type: "Contribution").should be_empty
    end

    it 'creates a new activity record when a contribution is added to an existing comversation' do
      conversation = FactoryGirl.create(:user_generated_conversation)
      contribution = FactoryGirl.create(:contribution_without_parent, conversation: conversation)
      a = Activity.last
      a.item_id.should == contribution.id
      a.item_type.should == 'Contribution'
    end

    it 'does not create a new activity record for contributions on preview' do
      conversation = FactoryGirl.create(:conversation)
      contribution = FactoryGirl.create(:unconfirmed_contribution, id: 5, conversation: conversation)
      a = Activity.last
      a.item_id.should_not == contribution.id
      a.item_type.should_not == 'Contribution'
    end

    it 'does not create a new activity record on update for contribution' do
      conversation = FactoryGirl.create(:conversation)
      top_level_contribution = FactoryGirl.create(:top_level_contribution, conversation: conversation)
      contribution = FactoryGirl.create(:comment, conversation: conversation, parent: top_level_contribution)
      contribution.update_attributes(content: "changed my mind...")
      a = Activity.where(item_id: contribution.id, item_type: 'Contribution')
      a.size.should == 1
    end

  end

  context "when destroying" do
    context 'a conversation' do
      it 'removes activity records when a conversation is deleted/destroyed' do
        conversation = FactoryGirl.create(:conversation)
        Activity.where(item_id: conversation.id, item_type: 'Conversation').should_not be_empty
        Conversation.destroy(conversation)
        Activity.where(item_id: conversation.id, item_type: 'Conversation').should be_empty
      end
    end

    it 'removes activity records when a contribution is deleted/destroyed' do
      contribution = FactoryGirl.create(:contribution)
      Contribution.destroy(contribution)
      Activity.where(item_id: contribution.id, item_type: 'Contribution').should be_empty
    end

    it 'removes activity records when a rating group is deleted/destroyed' do
      rating_group = FactoryGirl.create(:rating_group)
      RatingGroup.destroy(rating_group)
      Activity.where(item_id: rating_group.id, item_type: 'RatingGroup').should be_empty
    end
    
    it "removes the actvity records when a survey_response is destroyed" do
      given_a_user_have_voted
      Activity.where(item_id: @presenter.id, item_type: 'SurveyResponse').should_not be_empty
      @presenter.survey_response.destroy
      Activity.where(item_id: @presenter.id, item_type: 'SurveyResponse').should be_empty
    end
    
    it 'removes activity records when a petition is deleted/destroyed' do
      petition = FactoryGirl.create(:petition)
      Petition.destroy(petition)
      Activity.where(item_id: petition.id, item_type: 'Petition').should be_empty
    end
    
    it 'removes activity records when a petition signature is deleted/destroyed' do
      petition_signature = FactoryGirl.create(:petition_signature)
      PetitionSignature.destroy(petition_signature)
      Activity.where(item_id: petition_signature.id, item_type: 'PetitionSignature').should be_empty
    end

    it 'removes activity records when a reflection is deleted/destroyed' do
      reflection = FactoryGirl.create(:reflection)
      Reflection.destroy(reflection)
      Activity.where(item_id: reflection.id, item_type: 'Reflection').should be_empty
    end
    
    it 'removes activity records when a reflection comment is deleted/destroyed' do
      reflection_comment = FactoryGirl.create(:reflection_comment)
      ReflectionComment.destroy(reflection_comment)
      Activity.where(item_id: reflection_comment.id, item_type: 'ReflectionComment').should be_empty
    end

  end
end
