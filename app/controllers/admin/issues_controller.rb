class Admin::IssuesController < Admin::DashboardController

  #GET admin/issues/
  def index
    @issues = Issue.custom_order
  end

  #GET admin/issues/new
  def new
    @issue = Issue.new(params[:issue])
    @topics = Topic.all
  end

  #POST admin/issues
  def create
    @issue = Issue.new(params[:issue])

    params[:issue][:topic_ids] ||= []
    @issue.attributes = params[:issue]
    @issue.type = params[:issue][:type] if Issue::ALL_TYPES.include?(params[:issue][:type])

    if @issue.save
      redirect_to admin_issues_path
      flash[:notice] = "Thank you for submitting an issue"
    else
      @topics = Topic.all
      render :new
    end
  end

  #GET admin/issues/:id/edit
  def edit
    @issue = Issue.find(params[:id]).becomes(Issue)
    @topics = Topic.all
  end

  #PUT admin/issues/:id
  def update
    @issue = Issue.find(params[:id])

    params[:issue][:topic_ids] ||= []
    @issue.attributes = params[:issue]

    @issue.type = params[:issue][:type] if Issue::ALL_TYPES.include?(params[:issue][:type])

    if @issue.save
      redirect_to admin_issues_path
      flash[:notice] = "Thank you for updating the issue"
    else
      flash[:error] = @issue.errors[:base].join("<br/>")

      @issue = @issue.becomes(Issue)
      @topics = Topic.all
      render :edit
    end
  end

  #PUT admin/issues/update_order
  def update_order
    # validate parameters
    current_position = format_param(params[:current])
    next_position = format_param(params[:next])
    previous_position = format_param(params[:prev])

    if current_position.nil? || Issue.find_by_position(current_position).nil?
      raise "Current position cannot be nil and must exist"
    end

    if ((next_position.nil? || Issue.find_by_position(next_position).nil?) &&
      (previous_position.nil? || Issue.find_by_position(previous_position).nil?))
      raise "next or previous position must not be nil and exist"
    end

    Issue.set_position(current_position, next_position, previous_position)
    render :nothing => true

  rescue RuntimeError => e
    Issue.assign_positions
    respond_to do |format|
      format.html { render :text => e.message, :status => 403 }
      format.js { render :text => e.message, :status => 403 }
    end
  end

  #GET admin/issues/:id
  def show
    @issue = Issue.find(params[:id])
  end

  #DELETE admin/issues/:id
  def destroy
    @issue = Issue.find(params[:id])
    @issue.destroy
    redirect_to admin_issues_path
  end

  private

  def format_param(param)
    if !param.nil? && param.match(/^\d+$/)
      param.to_i
    else
      nil
    end
  end
end
