require 'spec_helper'

describe "Reflections" do
  describe "GET /reflections" do
    def mock_conversation(stubs={})
      @mock_conversation ||= mock_model(Conversation, stubs).as_null_object
    end
    
    def mock_reflection(stubs={})
      @mock_reflection ||= mock_model(Reflection, stubs).as_null_object
    end

    it "works! (now write some real specs)" do
      Conversation.stub(:find).with('7') { mock_conversation }
      mock_conversation.stub_chain(:managed_issue,:first).and_return(nil)
      Reflection.stub(:where) {mock_reflection}
      mock_reflection.stub(:order) {[]}
      get conversation_reflections_path :conversation_id => 7
      response.status.should be(200)
    end
  end
end
