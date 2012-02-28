class OpportunitiesController < ApplicationController
  before_filter :force_friendly_id, :only => :show

	# GET /opportunities
  def index
    @active = Opportunity.most_active.limit(3)
    @popular = Opportunity.top_visited.limit(3)
    @recent = Opportunity.latest_created.limit(3)
    @recommended = Opportunity.recommended.limit(3)

    @regions = Region.all
    @recent_items = Activity.most_recent_activity_items(3)
    render :index
  end

  # GET /opportunities/1
  def show
		@opportunity = Opportunity.includes(:conversation).find(params[:id])
		@conversation = @opportunity.conversation
	end

  private
  def force_friendly_id
    if params[:id].to_s =~ /^\d+$/i
      opportunity = Opportunity.find_by_id(params[:id])
      redirect_to request.parameters.merge({:id => opportunity.cached_slug, :status => :moved_permanently})
    end
  end
end