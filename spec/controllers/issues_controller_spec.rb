require 'spec_helper'

describe IssuesController do

  describe "GET index" do

    before(:each) do

      (1..2).each do
        Factory.create(:topic)
      end

      (1..2).each do
        Factory.create(:managed_issue)
      end

      factory_limit = 2
      (1..factory_limit).each do |i|
        Factory.create(:issue, :exclude_from_result => false, :topics => [Topic.first], :position => factory_limit-i)
      end

      (1..2).each do
        Factory.create(:issue, :exclude_from_result => true)
      end

    end

    it "uses all issues if there is no current topic" do
      get :index
      assigns(:issues).should == Issue.where(:type => 'Issue').where(:exclude_from_result => false).order(:position).all
    end

    it "assigns items to @recent_items" do
      item = mock_model(Contribution)
      activity = mock_model(Activity)
      Activity.should_receive(:most_recent_activity_items).and_return([item])
      get :index

      assigns(:recent_items).should == [item]
    end

    it "includes topics" do
      Topic.should_receive(:including_public_issues)
      get :index
    end

    it "assigns topics" do
      get :index
      assigns(:topics).should == Topic.including_public_issues.all
    end

    it "assigns current_topic if there is a param[:topic]" do
      get :index, :topic => Topic.first.id
      assigns(:current_topic).should == Topic.first
    end

    it "assigns subtitle if there is a topic" do
      get :index, :topic => Topic.first.id
      assigns(:subtitle).should == Topic.first.name
    end

    it "uses issues on a particular topic if there is a current topic" do
      get :index, :topic => Topic.first.id
      assigns(:issues).should == Topic.first.issues.standard_issue.published.order(:position).all
    end

  end

  describe "GET show" do

    context "with standard issues" do

      before(:each) do
        @user = Factory.create(:registered_user)
        sign_in @user
        @issue = Factory.create(:issue)
      end

      it "assigns the requested issue as @issue" do
        get :show, :id => @issue.id
        assigns(:issue).should == @issue
      end

      it "records a visit to the issue passing the current user" do
        count_before = Visit.where(:person_id => @user.id).where(:visitable_id => @issue.id).where(:visitable_type => "Issue").size
        get :show, :id => @issue.id
        count_after = Visit.where(:person_id => @user.id).where(:visitable_id => @issue.id).where(:visitable_type => "Issue").size
        count_after.should == count_before + 1
      end

      it "should assign people with most active conversation creators" do
        get :show, :id => @issue.id
        assigns(:people).class == ActiveRecord::Relation
      end

      it "will limit the most active conversation creators to 20" do
        get :show, :id => @issue.id
        assigns(:people).limit_value.should == 20
      end

    end

    context "with managed issues (aka Projects)" do

      let(:issue) do
        Factory.create(:managed_issue)
      end

      it "renders the index managed issue page when set" do
        issue.index = Factory.create(:managed_issue_page, issue: issue)
        issue.save
        get :show, :id => issue.id
        response.should render_template 'managed_issue_pages/show'
      end

      it "renders the standard show page when index page not set" do
        get :show, :id => issue.id
        response.should render_template 'show'
      end

    end

  end

end
