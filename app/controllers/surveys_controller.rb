class SurveysController < ApplicationController
  before_filter :require_user
  before_filter :find_survey, :only => [:show, :create_response]
  before_filter :allow_active_survey, :only => [:show]

  def show
    @survey_response_presenter = VoteResponsePresenter.new(:person_id => current_person.id, :survey_id => @survey.id)
    if @survey_response_presenter.allowed?
      render :template => "surveys/show_#{@survey.class.name.underscore}"
    else
      if @survey.show_progress?
        @vote_progress_service = VoteProgressService.new(@survey)
        render :template =>"surveys/show_#{@survey.class.name.underscore}_show_progress"
      else
        render :template => "surveys/show_#{@survey.class.name.underscore}_hide_progress"
      end
    end
  end

  def create_response
    @survey_response_presenter = VoteResponsePresenter.new({:person_id => current_person.id, :survey_id => @survey.id}.merge!(params[:survey_response_presenter]))
    # if it has been confirmed, then it can be saved
    if @survey_response_presenter.confirmed?
      if @survey_response_presenter.save
        flash[:vote_successful] = true
        respond_to do |format|
          format.html{redirect_to :action => :show}
          format.js{render :js => "document.location = '#{url_for(:action => :show)}';"}
        end
      else
        render :template => "surveys/show_#{@survey.class.name.underscore}"
      end
    else
      respond_to do |format|
        format.js{ render :js => render_to_string(:partial => "/surveys/#{@survey.class.name.underscore}_response_confirmation") }
        format.html{render :text => 'Javascript needs to be turned on to vote'}
      end
    end
  end

  # vote_successful modal dialog
  def vote_successful
    render :layout => nil
  end

protected

  def find_survey
      @survey = Survey.find(params[:id])
  end

  def allow_active_survey
    unless @survey.active?
      render :template => "surveys/show_#{@survey.class.name.underscore}_inactive"
    end
  end

end
