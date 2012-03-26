require 'spec_helper'

describe "Reflections" do
  describe "GET /reflections" do
    def mock_conversation(stubs={})
      @mock_conversation ||= mock_model(Conversation, stubs).as_null_object
    end

    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      Conversation.stub(:find).with('7') { mock_conversation }
      Reflection.stub(:where) {[]}
      get conversation_reflections_path :conversation_id => 7
      response.status.should be(200)
    end
  end
end
