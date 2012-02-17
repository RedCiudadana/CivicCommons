class IssuesController < ApplicationController
  layout 'category_index'
  before_filter :require_user, :only => [:create_contribution]

  # GET /issues
  def index
    @topics = Topic.including_public_issues
    @current_topic = Topic.find_by_id(params[:topic])
    @subtitle = @current_topic.name if @current_topic

    @search = @current_topic ? @current_topic.issues : Issue
    @issues = @search.standard_issue.published.custom_order.paginate(:page => params[:page], :per_page => 20)
    @issues.map! { |i| IssuePresenter.new(i) }

    @recent_items = Activity.most_recent_activity_items(3)
  end

  # GET /issues/1
  def show
    issue = Issue.includes(:conversations, :participants).find(params[:id])
    @issue = IssuePresenter.new(issue)
    @issue.visit!((current_person.nil? ? nil : current_person.id))
    setup_meta_info(@issue)

    if @issue.managed? and @issue.index
      @page = @issue.index
      render 'managed_issue_pages/show'
    else
      @latest_conversations = @issue.conversations.latest_updated.limit(3)
      all_conversations_on_issue = @issue.conversations.latest_updated
      @conversations = all_conversations_on_issue.paginate(:page => params[:page], :per_page => 6)
      @people = @issue.most_active_users.limit(20)
      @people_count = @issue.community_user_ids.length

      @conversation_comments = @issue.conversation_comments.most_recent
      @contributions = @issue.contributions.includes(:person).most_recent
      @recent_items = Activity.most_recent_activity_items_for_issue(@issue, 5)
    end
  end

  def create_contribution
    @issue = Issue.find(params[:id])
    params[:contribution].merge!(:issue_id => @issue.id)
    unless params[:contribution][:url].blank?
      embedly = EmbedlyService.new
      embedly.fetch_and_merge_params!(params)
    end
    @contribution = Contribution.create_node(params[:contribution], current_person, true)
    Subscription.create_unless_exists(current_person, @issue)

    respond_to do |format|
      if @contribution.save
        format.html { render :partial => 'issues/create_contribution', :locals => {:issue => @issue}, :status => :created }
        format.js
      else
        format.html { render :json => {:errors => @contribution.errors.full_messages }, :status => :unprocessable_entity }
        format.js { render :json => {:errors => @contribution.errors.full_messages }, :status => :unprocessable_entity }
      end
    end
  end

end
