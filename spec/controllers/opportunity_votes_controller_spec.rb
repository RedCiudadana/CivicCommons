require 'spec_helper'

describe OpportunityVotesController do
  def mock_person(stubs={})
    @mock_person ||= mock_model(Person, stubs).as_null_object
  end
  
  def mock_vote(stubs={})
    @mock_vote ||= mock_model(Vote,stubs).as_null_object
  end
  
  def mock_issue(stubs={})
    @mock_issue ||= mock_model(Issue, stubs).as_null_object
  end

  def mock_conversation(stubs={})
    @mock_conversation ||= mock_model(Conversation, stubs).as_null_object
  end
  
  before(:each) do
    controller.stub(:current_person).and_return(mock_person)
    Conversation.stub(:find).and_return(mock_conversation(:id => 123))
  end
  
  describe "GET new" do
    it "assigns a new vote as @vote" do
      Vote.stub(:new) { mock_vote }
      get :new, :conversation_id => 123
      assigns(:vote).should be(mock_vote)
    end
    it "should build some option(s)" do
      Vote.stub(:new) { mock_vote }
      mock_vote.should_receive(:options).and_return(mock_vote)
      mock_vote.should_receive(:build)
      
      get :new, :conversation_id => 123
    end
  end
  
  describe "POST create" do
    context "on successful save" do
      it "should redirect to the conversation_vote_url" do
        @conversation = mock_conversation(:id => 123)
        @vote = mock_vote(:id => 1234)
        Vote.stub!(:new) { @vote }
        @vote.should_receive(:surveyable=).with(@conversation)
        @vote.should_receive(:person=).with(mock_person)
        @vote.should_receive(:show_progress=).with(true)
        @vote.stub!(:save).and_return(true)
        post :create, :conversation_id => 123
        response.should redirect_to conversation_vote_path(123, 1234, :anchor => 'opportunity-nav')
      end
    end
    context "on unsuccessful save" do
      it "should render the same action" do
        Vote.stub(:new) { mock_vote }
        mock_vote.should_receive(:surveyable=).with(mock_conversation(:id => 123))
        mock_vote.should_receive(:person=).with(mock_person)
        mock_vote.should_receive(:show_progress=).with(true)
        mock_vote.stub!(:save).and_return(false)
        post :create, :conversation_id => 123
        response.should render_template 'opportunity_votes/new'
      end
    end
  end
end
