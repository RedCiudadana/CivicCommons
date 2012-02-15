require 'spec_helper'

describe ConversationsController do

  def mock_conversation(stubs={})
    @mock_conversation ||= mock_model(Conversation, stubs).as_null_object
  end
  
  def mock_content_item(stubs={})
    @mock_content_item ||= mock_model(ContentItem, stubs).as_null_object
  end

  describe "not logged in" do
    before(:each) do
      @controller.stub(:current_person).and_return(nil)
    end

    {:new => :get, :create => :post}.each do |action, *methods|

      methods.each do |method|
        it "redirects to login for #{method} => :#{action}" do
          send(method, action)
          response.should redirect_to new_person_session_path
        end
      end
    end
  end
  
  describe "before_filters" do
    describe "force_friendly_id" do
      describe "on :show" do
        def given_conversation
          @conversation = mock_conversation(:id => 1234, :cached_slug => 'friendly-id-here')
        end
        it "should redirect to the same url but using the correct friendly id if numerical id is passed" do
          given_conversation
          Conversation.stub!(:find_by_id).and_return(@conversation)
          get :show, :id => @conversation.id
          response.should redirect_to '/conversations/friendly-id-here'
        end
        it "should allow the parameters to be passed on redirect" do
          given_conversation
          Conversation.stub!(:find_by_id).and_return(@conversation)
          get :show, :id => @conversation.id, :hello => 'hi'
          response.should redirect_to '/conversations/friendly-id-here?hello=hi'
        end
        it "should not redirect if friendly id is passed" do
          given_conversation
          Conversation.stub_chain(:includes, :find).and_return(@conversation)
          RatingGroup.stub!(:ratings_for_conversation_by_contribution_with_count).and_return(nil)
          get :show, :id => @conversation.cached_slug
          response.should render_template :show
          response.should_not redirect_to '/conversations/friendly-id-here'
        end
      end
    end
  end

  describe "GET index" do

    before(:each) do
      @old_conversation = Factory.create(:conversation, {:created_at => (Time.now - 2.days), :updated_at => (Time.now - 30.seconds), :last_visit_date => Time.now, :recent_visits => 2})
      @new_conversation = Factory.create(:conversation, {:created_at => (Time.now - 1.day), :updated_at => (Time.now - 2.seconds), :last_visit_date => Time.now, :recent_visits => 1})
    end

    it "assigns all conversations as @active, @popular, and @recent" do
      get :index
      assigns(:active).length.should == 0 # since no contributions were made
      assigns(:popular).first.should == @old_conversation
      assigns(:popular).last.should == @new_conversation
      assigns(:recent).first.should == @new_conversation
      assigns(:recent).last.should == @old_conversation
    end

    it "does not duplicate avatars for recent contributions on the same conversation" do
      @person = Factory.create(:registered_user)
      Factory.create(:contribution, { :conversation => @new_conversation, :person => @person })
      Factory.create(:contribution, { :conversation => @new_conversation, :person => @person })
      Factory.create(:contribution, { :conversation => @new_conversation, :person => @person })

      get :index

      assigns(:active).first.contributions.size.should == 3
      assigns(:active).first.participants.size.should == 1
    end

  end

  describe "GET rss" do
 
    before(:each) do
      (1..5).each do |i|
        Factory.create(:conversation)
      end
        @old_convo = Factory.create(:conversation, created_at: 2.months.ago)
    end

    it "assigns conversations as @conversations" do
      get :rss, format: 'xml'
      assigns(:conversations).should_not be_empty
    end

    it "does not retrieve conversations more than 1 month old" do
      get :rss, format: 'xml'
      assigns(:conversations).should_not include @old_convo 
    end

    it "sorts conversations by created_at, descending" do
      get :rss, format: 'xml'
      last_date = nil
      assigns(:conversations).each do |convo|
        convo.created_at.should >= last_date unless last_date.nil?
        last_date = convo.created_at
      end
    end

 end

  describe "GET show" do
    before(:each) do
      @person = Factory.create(:registered_user)
      @controller.should_receive(:current_person).at_least(1).and_return(@person)
      @convo = Factory.create(:conversation)
    end

    def do_get
      get :show, :id => @convo.id
    end

    it "assigns the requested conversation as @conversation" do
      do_get
      assigns(:conversation).should == @convo
    end

    it "records a visit to the conversation passing the current user" do
      do_get
      convo = Conversation.find_by_id(@convo.id)
      convo.total_visits.should == @convo.total_visits + 1
      convo.recent_visits.should == @convo.recent_visits + 1
      Visit.where("person_id = #{@person.id} and visitable_id = #{@convo.id}").size.should == 1
    end
  end

  describe "GET new" do
    before(:each) do
      @controller.stub(:current_person).and_return(Factory.build(:normal_person))
      Conversation.stub(:new) { mock_conversation }
      Issue.stub(:alphabetical) { :all_issues }
      get :new, :accept => true
    end
    
    it "should receive get_content_item" do
      controller.should_receive(:get_content_item)
      get :new, :accept => true
    end

    it "redirects to responsibilities if :accept is not true" do
      get :new, :accept => nil
      response.should redirect_to(conversation_responsibilities_path)
    end

    it "assigns new conversation as @conversation" do
      assigns(:conversation).should be mock_conversation
    end
    
    describe "on radioshows" do
      it "should find content_item" do
        ContentItem.should_receive(:find).with(1).and_return(mock_content_item)
        get :new, :accept => true, :radioshow_id => 1
      end
      
      it "should not find content_item if radioshow_id is not passed" do
        ContentItem.should_not_receive(:find).with(1).and_return(mock_content_item)
        get :new, :accept => true
      end
    end
    describe "on blogpost" do
      it "should find content_item" do
        ContentItem.should_receive(:find).with(1).and_return(mock_content_item)
        get :new, :accept => true, :blog_id => 1
      end
      
      it "should not find content_item if radioshow_id is not passed" do
        ContentItem.should_not_receive(:find).with(1).and_return(mock_content_item)
        get :new, :accept => true
      end
    end
    
  end

  describe "POST create" do
    before(:each) do
      @person = Factory.build(:normal_person, :id => 1)
      @controller.stub(:current_person) { @person }
    end

    def do_create
      post :create, :conversation => {}
    end
    
    it "should receive get_content_item" do
      controller.should_receive(:get_content_item)
      do_create
    end

    describe "with valid params" do
      before(:each) do
        Conversation.stub(:new) { mock_conversation(:save => true) }
      end

      it "assigns created conversation to @conversation" do
        do_create
        assigns[:conversation].should be mock_conversation
      end

      it "creates conversation with checked issue_ids" do
        #Conversation.should_receive(:new).with({'issue_ids' => ["5","10"]})
        post :create, :conversation => {:issue_ids => ["5", "10"]}
        assigns(:conversation).issues.each do |issue|
          [5, 10].should include issue.id
        end
      end

      it "redirects to invite page to Send Invitations" do
        mock_conversation(:id => '35', :save => true)
        do_create
        response.should redirect_to new_invite_path(:source_type => :conversations, :source_id => '35', :conversation_created => true)
      end
      
      describe "on radioshows" do
        it "should find content_item" do
          ContentItem.should_receive(:find).with(1).and_return(mock_content_item)
          post :create, :conversation => {}, :radioshow_id => 1
        end

        it "should not find content_item if radioshow_id is not passed" do
          ContentItem.should_not_receive(:find).with(1).and_return(mock_content_item)
          post :create, :conversation => {}
        end
      end
      describe "on blogpost" do
        it "should find content_item" do
          ContentItem.should_receive(:find).with(1).and_return(mock_content_item)
          post :create, :conversation => {}, :blog_id => 1
        end

        it "should not find content_item if radioshow_id is not passed" do
          ContentItem.should_not_receive(:find).with(1).and_return(mock_content_item)
          post :create, :conversation => {}
        end
      end
      
    end

    describe "with invalid params" do
      before(:each) do
        Conversation.stub(:new) { mock_conversation(:save => false) }
      end

      it "renders :new template" do
        do_create
        response.should render_template(:new)
      end

      it "populates error messages" do
      end
    end
    
    
  end

  describe "GET responsibilities" do
    it "should receive get_content_item" do
      controller.should_receive(:get_content_item)
      get :responsibilities
    end
  end
end
