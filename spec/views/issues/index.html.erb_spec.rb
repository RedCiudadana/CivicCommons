require 'spec_helper'
describe '/issues/index.html.erb' do

  before(:each) do
    @issue = Factory.create(:issue,
      index_summary: 'custom index summary',
      summary: 'original summary'
    )
  end

  it "should show the Issue's index summaries" do
    @recent_items = []
    @topics = []
    @issues = Issue.standard_issue.published.paginate(:page => params[:page], :per_page => 20)
    @issues.map! { |i| IssuePresenter.new(i) }
    render
    rendered.should contain 'custom index summary'
  end

end
