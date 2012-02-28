require 'spec_helper'

describe OpportunitiesController do

  describe "GET index" do
    it "assigns active opportunities as @active" do
      conversation = Factory.create(:conversation)
      opportunity = Factory.create(:opportunity, conversation: conversation)
      get :index
      assigns[:active].length.should == 0
    end

    it "assigns popular opportunities as @popular" do
      conversation = Factory.create(:conversation, last_visit_date: Time.now, :recent_visits => 2)
      opportunity = Factory.create(:opportunity, conversation: conversation)
      get :index
      assigns[:popular].should == [opportunity]
    end

    it "assigns most recent opportunities as @recent" do
      opportunity = Factory.create(:opportunity)
      get :index
      assigns[:recent].should == [opportunity]
    end

    it "assigns recommended opportunities as @recommended" do
      conversation = Factory.create(:conversation, staff_pick: true)
      opportunity = Factory.create(:opportunity, conversation: conversation)
      get :index
      assigns[:recommended].should == [opportunity]
    end

    it "assigns site regions as @regions" do
      get :index
      assigns[:active].should == Region.all
    end

    it "assigns recent site activity as @recent_items" do
      get :index
      assigns[:active].should == Activity.most_recent_activity_items(3)
    end

  end

  describe "GET show" do
    it "assigns the requested Opportunity as @opportunity" do
      opportunity = Factory.create(:opportunity)
      get :show, :id => opportunity.to_param
      assigns[:opportunity].should == opportunity
    end

    it "assigns the requested Opportunity's Conversation as @conversation" do
      opportunity = Factory.create(:opportunity)
      get :show, :id => opportunity.to_param
      assigns[:conversation].should == opportunity.conversation
    end
  end

  describe "before_filters" do
    describe "force_friendly_id" do
      describe "on :show" do

        def given_opportunity
          @opportunity = mock_opportunity(:id => 1234, :cached_slug => 'friendly-id-here')
        end

        def mock_opportunity(stubs={})
          @mock_opportunity ||= mock_model(Opportunity, stubs).as_null_object
        end

        it "should redirect to the same url but using the correct friendly id if numerical id is passed" do
          given_opportunity
          Opportunity.stub!(:find_by_id).and_return(@opportunity)
          get :show, :id => @opportunity.id
          response.should redirect_to '/opportunities/friendly-id-here'
        end
        it "should allow the parameters to be passed on redirect" do
          given_opportunity
          Opportunity.stub!(:find_by_id).and_return(@opportunity)
          get :show, :id => @opportunity.id, :hello => 'hi'
          response.should redirect_to '/opportunities/friendly-id-here?hello=hi'
        end
        it "should not redirect if friendly id is passed" do
          given_opportunity
          Opportunity.stub_chain(:includes, :find).and_return(@opportunity)
          RatingGroup.stub!(:ratings_for_conversation_by_contribution_with_count).and_return(nil)
          get :show, :id => @opportunity.cached_slug
          response.should render_template :show
          response.should_not redirect_to '/opportunities/friendly-id-here'
        end
      end
    end
  end

end
