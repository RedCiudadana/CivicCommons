class OpportunityVotesController < ApplicationController
  layout 'opportunity'
  before_filter :require_user, :except => [:show]
  before_filter :find_conversation
  before_filter :restrict_voter_access, :only => [:select_options,:create_select_options,:rank_options, :create_rank_options]
  DEFAULT_NUM_OF_OPTIONS = 1
  
  def new
    @vote = Vote.new(:max_selected_options => 1)
    DEFAULT_NUM_OF_OPTIONS.times do |i|
      @vote.options.build(:position => i+1)
    end
  end
  
  def create
    @vote = Vote.new(params[:vote])
    @vote.surveyable = @conversation
    @vote.person = current_person
    @vote.show_progress = true
    
    if @vote.save
      redirect_to(conversation_vote_path(@conversation, @vote, :anchor => 'opportunity-nav'), :notice => 'Vote was successfully created.')
    else
      render :action => "new"
    end
  end
  
  def show
    @vote = @conversation.surveys.find(params[:id])
    @vote_response_presenter = VoteResponsePresenter.new(:person_id => try(:current_person).try(:id), :survey_id => @vote.id)    
  end
  
  def select_options
    @vote = @conversation.surveys.find(params[:id])
    selected_option_ids = params[:selected_option_ids].to_s.split(',') || []
    @vote_response_presenter = VoteResponsePresenter.new({:person_id => current_person.id, :survey_id => @vote.id}.merge!(:selected_option_ids => selected_option_ids))
    render :action => :show
  end

  def create_select_options
    vote_response_params = params[:vote_response_presenter] || {}
    @vote = @conversation.surveys.find(params[:id])
    @vote_response_presenter = VoteResponsePresenter.new({:person_id => current_person.id, :survey_id => @vote.id}.merge!(vote_response_params))
    if @vote_response_presenter.valid_selected_options?
      redirect_to rank_options_conversation_vote_path(@conversation,@vote,:selected_option_ids => @vote_response_presenter.selected_option_ids.join(','), :anchor => 'opportunity-nav')
    else
      render :action => :show 
    end
  end
  
  def rank_options
    selected_option_ids = params[:selected_option_ids].to_s.split(',') || []
    @vote = @conversation.surveys.find(params[:id])
    @vote_response_presenter = VoteResponsePresenter.new({:person_id => current_person.id, :survey_id => @vote.id}.merge!(:selected_option_ids => selected_option_ids))
  end
  
  def create_rank_options
    vote_response_params = params[:vote_response_presenter] || {}
    @vote = @conversation.surveys.find(params[:id])
    @vote_response_presenter = VoteResponsePresenter.new({:person_id => current_person.id, :survey_id => @vote.id}.merge!(vote_response_params))
    if @vote_response_presenter.save
      flash[:notice] = "Thank you for voting!"
      redirect_to rank_options_conversation_vote_path(@conversation,@vote, :anchor => 'opportunity-nav')
    else
      render :action => :rank_options 
    end
    
  end
  
  
  
  protected
  def find_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end
  
  def restrict_voter_access
    vote = VoteResponsePresenter.new({:person_id => current_person.id, :survey_id => params[:id]})
    redirect_to conversation_vote_path(@conversation,params[:id], :anchor => 'opportunity-nav') unless vote.allowed?
  end
end
