class ContributionsController < ApplicationController
  include ContributionsHelper
  include ConversationsHelper

  before_filter :load_conversation, only: [:edit, :update, :moderate, :moderated]
  before_filter :verify_admin, only: [:moderate, :moderated]
  before_filter :require_user, only: [ :create ]

  def create
    @conversation = Conversation.find(params[:conversation_id])
    unless params[:contribution][:url].blank?
      embedly = EmbedlyService.new
      embedly.fetch_and_merge_params!(params)
    end
    @contribution = Contribution.new(params[:contribution])
    @contribution.person = current_person
    @contribution.item = @conversation
    @contribution.confirmed = true

    if @contribution.save
      Subscription.create_unless_exists(current_person, @contribution.item)
      @ratings = RatingGroup.default_contribution_hash
    end

    respond_to do |format|
      format.js { render "conversations/create_node_contribution" }
      format.html do
        # NOTE: this path does poor error handling - Jerry
        if @contribution.save
          redirect_to conversations_node_show_path(@conversation, @contribution.id)
        elsif @contribution.parent
          redirect_to conversations_node_show_path(@conversation, @contribution.parent.id)
        else
          redirect_to conversations_path(@conversation)
        end
      end
    end
  end

  def destroy
    @contribution = Contribution.find(params[:id])
    respond_to do |format|
      if @contribution.destroy_by_user(current_person)
        format.js   { render :nothing => true, :status => :ok }
      else
        format.js   { render :json => @contribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create_confirmed_contribution
    @contribution = Contribution.create_node(params[:contribution], current_person, true)
    redirect_to("#{contribution_parent_page(@contribution)}#contribution#{@contribution.id}",
                    :notice => 'Contribution was successfully created.')
  end

  def edit
    @contribution = Contribution.find(params[:id])
    respond_to do |format|
      format.js { render 'conversations/edit_contribution_tool' }
    end
  end

  def show
    @contribution = Contribution.find(params[:id])
    @contributions = @contribution.self_and_descendants
    @ratings = RatingGroup.ratings_for_conversation_by_contribution_with_count(@contribution.conversation, current_person)
    respond_to do |format|
      format.js { render(:partial => "conversations/threaded_contribution_template", :locals => { :ratings => @ratings }, :collection => @contributions, :as => :contribution) }
    end
  end

  def update
    @contribution = Contribution.find(params[:id])
    @contributions = @contribution.self_and_descendants
    attributes = { contribution: params[:contribution][params[:id]] }
    unless attributes[:contribution][:url].blank?
      embedly = EmbedlyService.new
      embedly.fetch_and_merge_params!(attributes)
    end

    success = @contribution.update_attributes_by_user(attributes, current_person)
    respond_to do |format|
      if success
        ratings = RatingGroup.ratings_for_conversation_by_contribution_with_count(@contribution.conversation, current_person)
        format.html do 
          if request.xhr?
            render(:partial => "conversations/threaded_contribution_template", :locals => { :ratings => ratings }, :collection => @contributions, :as => :contribution)
          else
            redirect_to conversation_node_path(@contribution) 
          end
        end
        format.js { render(:partial => "conversations/threaded_contribution_template", :locals => { :ratings => ratings }, :collection => @contributions, :as => :contribution) }
      else
        format.js { render :json => @contribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  def moderate
    @contribution = Contribution.find(params[:id])
  end

  def moderated
    @contribution = Contribution.find(params[:id])
    @contribution.moderate_content(params, current_person)
    redirect_to conversation_path(@conversation)
  end

private

  def load_conversation
    if params.has_key?(:conversation_id)
      @conversation = Conversation.find(params[:conversation_id])
    end
  end

end
