class ProjectsController < ApplicationController
  layout 'category_index'

  # GET /projects
  def index
    @projects = Issue.managed_issue.published.custom_order.paginate(:page => params[:page], :per_page => 20)
    @recent_items = Activity.most_recent_activity_items(3)
  end

end
