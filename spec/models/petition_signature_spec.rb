require 'spec_helper'

describe PetitionSignature do
  describe "validation" do
    it "should validate presence of petition_id" do
      should validate_presence_of :petition_id
    end
    it "should validate presence of person_id" do
      should validate_presence_of :person_id
    end
  end
  describe "Associations" do
    it "should belong_to petition" do
      should belong_to(:petition)
    end
    it "should belong_to person" do
      should belong_to(:person)
    end
  end
  context "delegation" do
    before(:each) do
      @petition_signature = FactoryGirl.build(:petition_signature)
    end
    it "petition converastion to a petitions conversation" do
      @petition_signature.petition_conversation.should == @petition_signature.petition.conversation
    end
    it "petition name to a petitions title" do
      @petition_signature.petition_name.should == @petition_signature.petition.title
    end
    it "petition title to a petitions title" do
      @petition_signature.petition_title.should == @petition_signature.petition.title
    end
    it "petition description to a petitions description" do
      @petition_signature.petition_description.should == @petition_signature.petition.description
    end
    it "petition signer name to a petition signature name" do
      @petition_signature.signer_name.should == @petition_signature.person.name
    end
  end
  
  context 'conversation_id' do
    it "should return the right conversation id" do
      @petition_signature = FactoryGirl.build(:petition_signature)
      @petition_signature.conversation_id.should == Conversation.last.id
    end
  end
  
end
