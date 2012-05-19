require 'spec_helper'

describe ActionsController do

  def stub_conversation(stubs={})
    @stub_conversation ||= stub_model(Conversation, stubs).as_null_object
  end
    
  def stub_person(stubs={:id => 111})
    @stub_person ||= stub_model(Person, stubs).as_null_object
  end

  before(:each) do
    @controller.stub!(:require_user).and_return(true)
    @controller.stub!(:current_person).and_return(stub_person)
    Conversation.stub!(:find).and_return(stub_conversation)
    stub_conversation.stub!(:action_participants).and_return([])
  end
  
  describe "index" do
    it "should find the conversation" do
      Conversation.should_receive(:find).with(123).and_return(stub_conversation)
      get :index, :conversation_id => 123
    end
    it "should get the conversation actions" do
      actions_double = double
      stub_conversation.should_receive(:actions).and_return(actions_double)
      actions_double.stub(:order)
      get :index, :conversation_id => 123
    end
    it "should order DESC" do
      actions_double = double
      stub_conversation.stub(:actions).and_return(actions_double)
      actions_double.should_receive(:order).with('id DESC')
      get :index, :conversation_id => 123
    end
    it "should return the conversation participants" do
      stub_conversation.should_receive(:action_participants)
      get :index, :conversation_id => 123
    end
  end
end
