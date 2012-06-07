require 'spec_helper'

describe ReflectionComment do
  describe "associations" do
    it { should belong_to :reflection}
    it { should belong_to :person}
  end
  describe "validations" do
    it { should validate_presence_of :body}
  end
  it "should have conversation_id" do
    @reflection_comment = FactoryGirl.create(:reflection_comment)
    @reflection_comment.conversation_id.should_not be_nil
    @reflection_comment.conversation_id.should == Conversation.last.id
  end
end
