class ConversationsController < ApplicationController
  layout 'category_index'

  before_filter :force_friendly_id, :only => :show
  before_filter :require_user, :only => [
    :new,
    :create,
    :new_node_contribution,
    :preview_node_contribution,
    :confirm_node_contribution,
    :toggle_rating,
    :create_from_blog_post,
    :create_from_radioshow,
  ]

  # GET /conversations
  def index
    @active = Conversation.most_active.limit(3)
    @popular = Conversation.get_top_visited(3)
    @recent = Conversation.latest_created.limit(3)
    @recommended = Conversation.recommended.limit(3)

    @regions = Region.all
    @recent_items = Activity.most_recent_activity_items(3)
    render :index
  end

  # GET /conversations/rss
  def rss
    @conversations = Conversation.where("created_at >= '#{1.month.ago}'").order(:created_at => :desc)
    respond_to do |format|
      format.html { redirect_to(conversations_url) }
      format.xml
    end
  end

  def responsibilities
    get_content_item(params)
  end

  def filter
    @filter = params[:filter]
    @conversations = Conversation.filtered(@filter).paginate(:page => params[:page], :per_page => 12)

    @regions = Region.all
    @recent_items = Activity.most_recent_activity_items(3)
    render :filter
  end

  # GET /conversations/1
  def show
    @conversation = Conversation.includes(:issues).find(params[:id])
    @conversation.visit!((current_person.nil? ? nil : current_person.id))
    @contributions = Contribution.includes(:rating_groups, :person).for_conversation(@conversation)
    @ratings = RatingGroup.ratings_for_conversation_by_contribution_with_count(@conversation, current_person)

    # Build rating totals into contribution
    # @contributions.each do |c|
    #   c.ratings       #=> {'some-descriptor' => {:total => 5, :person => true}, 'some-other' => 0, 'and-again' => 1}
    # end
    @top_level_contributions = @contributions.select{ |c| c.top_level_contribution? }
    # grab all direct contributions to conversation that aren't TLC
    @conversation_contributions = @contributions.select{ |c| !c.top_level_contribution? && c.parent_id.nil? }

    @top_level_contribution = Contribution.new # for conversation comment form
    @tlc_participants = @top_level_contributions.collect{ |tlc| tlc.owner }

    @latest_contribution = @conversation.confirmed_contributions.most_recent.first

    @recent_items = Activity.most_recent_activity_items_for_conversation(@conversation, 5)

    setup_meta_info(@conversation)

    respond_to do |format|
      format.any{ render :show }
      format.embed do
        html = render_to_string
        json = {
          :html => html,
          :js => ['/javascripts/lib/conversations/show_embed.js']
          }
        render_widget(json)
      end
    end
  end

  def activities
    @page = params[:page].present? ? params[:page].to_i : 1
    @hide_container = params[:hide_container]
    @per_page = 5
    @offset = @per_page * (@page - 1)

    @conversation = Conversation.find(params[:id])
    
    # Added 1 to @per_page to see if there is a next page
    @recent_items = Activity.most_recent_activity_items_for_conversation(@conversation, @per_page + 1, @offset)
    @next_page = @recent_items.length > @per_page
    
    # pop the last item, because it was temporarily used to see if there is a next page.
    @recent_items.pop 

    respond_to do |format|
      format.embed do
        html = render_to_string
        json = {
          :html => html,
          :page => @page,
          :next_page => @next_page,
          :js => ['/javascripts/lib/conversations/activities.embed.js']
          }
        render_widget(json)
      end
    end
  end

 def node_conversation
    @contribution = Contribution.find(params[:id])
    @contributions = @contribution.descendants.confirmed.includes(:person)
    @contribution.visit!((current_person.nil? ? nil : current_person.id))

    respond_to do |format|
      format.js { render :partial => "conversations/node_conversation", :layout => false}
      format.html { render :partial => "conversations/node_conversation", :layout => false}
    end
  end

  def node_permalink
    contribution = Contribution.find(params[:id])
    @contributions = contribution.self_and_ancestors
    @top_level_contribution = @contributions.root
    contribution.visit!((current_person.nil? ? nil : current_person.id))

    respond_to do |format|
      format.js
    end
  end

  def new_node_contribution
    @contribution = Contribution.find_or_new_unconfirmed(params, current_person)
    respond_to do |format|
      format.js { render(:partial => "conversations/tabbed_post_box", :locals => {:div_id => params[:div_id], :layout => false}) }
      format.html { render(:partial => "conversations/tabbed_post_box", :locals => {:div_id => params[:div_id], :layout => false}) }
    end
  end

  #TODO Test, baby. Test!
  def preview_node_contribution

    errors = []
    unless params[:contribution][:url].blank?
      embedly = EmbedlyService.new
      embedly.fetch_and_merge_params!(params)
    end
    @contribution = Contribution.update_or_create_node(params[:contribution], current_person)

    if @contribution.invalid?
      errors = @contribution.errors.full_messages
    elsif embedly and (embedly.bad_request? or embedly.not_found?)
      errors = ["There was a problem retrieving information for '#{params[:contribution][:url]}'"]
    elsif embedly and not embedly.ok?
      errors = ['There was a problem with our system. Please try again.']
    end

    ratings = RatingGroup.ratings_for_conversation_by_contribution_with_count(@contribution.conversation, current_person)

    respond_to do |format|
      if errors.size == 0
        format.js   { render(:partial => "conversations/new_contribution_preview", :locals => { :div_id => params[:div_id], :layout => false, :ratings => ratings }) }
        format.html { render(:partial => "conversations/new_contribution_preview", :locals => { :div_id => params[:div_id], :layout => 'application', :ratings => ratings }) }
      else
        format.js   { render :json => errors, :status => :unprocessable_entity }
        format.html { render :text => errors, :status => :unprocessable_entity }
      end
    end
  end

  #TODO: consider moving this to its own controller?
  def confirm_node_contribution
    @contribution = Contribution.unconfirmed.find_by_id_and_owner(params[:contribution][:id], current_person.id)
    @ratings = RatingGroup.default_contribution_hash

    respond_to do |format|
      if @contribution.confirm!
        Subscription.create_unless_exists(current_person, @contribution.item)
        format.js   { render :partial => "threaded_contribution_template", :locals => { :contribution => @contribution, :ratings => @ratings }, :status => (params[:preview] ? :accepted : :created) }
        format.html   { render :partial => "threaded_contribution_template", :locals => { :contribution => @contribution, :ratings => @ratings }, :status => (params[:preview] ? :accepted : :created) }
      else
        format.js   { render :json => @contribution.errors, :status => :unprocessable_entity }
        format.html { render :text => @contribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /conversations/new
  def new
    return redirect_to :conversation_responsibilities unless params[:accept]
    get_content_item(params)
    @conversation = Conversation.new
    render :new
  end

  # GET /conversations/1/edit
  # NOT IMPLEMENTED YET, I.E. NOT ROUTEABLE
  def edit
    @conversation = Conversation.find(params[:id])
  end

  # POST /conversations
  def create
    prep_convo(params)

    respond_to do |format|
      if @conversation.save
        format.html { redirect_to(new_invite_path(:source_type => :conversations, :source_id => @conversation.id, :conversation_created => true), :notice => 'Your conversation has been created!') }
      else
        format.html { render :new }
      end
    end
  end

  # PUT /conversations/blog/:id
  def create_from_blog_post
    @blog_post = ContentItem.find(params[:id])
    if request.xhr?
      render partial: 'shared/redirect_after_xhr', locals: { url: blog_url(@blog_post) }
    elsif @blog_post.conversation
      redirect_to conversation_url(@blog_post.conversation)
    else
      params[:conversation][:summary] = "<em>This is a conversation about a blog post from #{@blog_post.author.name}: <a href=\"#{blog_url(@blog_post)}\">#{@blog_post.title}</a></em><br/><br/>#{@blog_post.summary}"
      params[:conversation][:title] = "Blog Post: #{@blog_post.title}"
      params[:conversation][:zip_code] = "ALL"
      prep_convo(params)
      if @conversation.save
        @blog_post.conversation = @conversation
        @blog_post.save
        redirect_to conversation_path(@conversation)
      else
        render 'blog/show'
      end
    end
  end

  # PUT /conversations/radio/:id
  def create_from_radioshow
    @radioshow = ContentItem.find(params[:id])
    if request.xhr?
      render partial: 'shared/redirect_after_xhr', locals: { url: radioshow_url(@radioshow) }
    else
      params[:conversation][:summary] = "<em>This is a conversation about The Civic Commons Radio <a href=\"#{radioshow_url(@radioshow)}\">#{@radioshow.title}</a></em><br/><br/>#{@radioshow.summary}"
      params[:conversation][:title] = "The Civic Commons Radio #{@radioshow.title}"
      params[:conversation][:zip_code] = "ALL"
      prep_convo(params)
      if @conversation.save
        @radioshow.conversations << @conversation
        redirect_to conversation_path(@conversation)
      else
        render 'radioshow/show'
      end
    end
  end

  # PUT /conversations/1
  # NOT IMPLEMENTED YET, I.E. NOT ROUTEABLE
  def update
    @conversation = Conversation.find(params[:id])

    if @conversation.update_attributes(params[:conversation])
      redirect_to(@conversation, :notice => 'Conversation was successfully updated.')
    else
      render :action => "edit", :status => :unprocessable_entity
    end
  end

  def toggle_rating
    @contribution = Contribution.find(params[:contribution_id])
    @rating_descriptor = RatingDescriptor.find_by_title(params[:rating_descriptor_title])

    @rating_group = RatingGroup.toggle_rating!(current_person, @contribution, @rating_descriptor)
    respond_to do |format|
      format.js
    end
  end

  private

  def force_friendly_id
    if params[:id].to_s =~ /^\d+$/i
      conversation = Conversation.find_by_id(params[:id])
      redirect_to request.parameters.merge({:id => conversation.cached_slug, :status => :moved_permanently})
    end
  end

  def prep_convo(params)
    @conversation = Conversation.new(params[:conversation])

    get_content_item(params)
    @conversation.content_items = [@content_item] if @content_item.present?

    @conversation.person = current_person
    @conversation.from_community = true
    @conversation.started_at = Time.now
    @conversation.contributions.each do |contribution|
      contribution.confirmed = true
      contribution.item = @conversation
    end
  end

  def get_content_item(params)
    if params[:radioshow_id] || params[:blog_id]
      @content_item = ContentItem.find(params[:radioshow_id]||params[:blog_id])
      @start_from = @content_item.content_type
    end
  end


end
