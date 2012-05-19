require 'spec_helper'
include ControllerMacros

describe "reflections/show.html.erb" do
  before(:each) do
    @reflection = FactoryGirl.create(:reflection_with_comments, title: 'Custom Title', details: 'Custom Details')
  end

  it "renders attributes in <p>" do
    @view.stub!(:signed_in?).and_return(false)
    assign(:conversation, @reflection.conversation)
    assign(:reflection, @reflection)
    assign(:comments, @reflection.comments)
    assign(:comment, @reflection.comments.new)
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Custom Title/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Custom Details/)
  end

  it "renders the moderation tools for reflection if logged in as an admin" do
    login_admin
    assign(:conversation, @reflection.conversation)
    assign(:reflection, @reflection)
    assign(:comments, @reflection.comments)
    assign(:comment, @reflection.comments.new)
    render
    rendered.should match(/<div class=\"main-content\">\s*<p class=\"fl-right alert alert-admin\">\s*<strong>Moderate:<\/strong>/)
  end

  it "does not render the moderation tools for reflection if not logged in as an admin" do
    login_user
    assign(:conversation, @reflection.conversation)
    assign(:reflection, @reflection)
    assign(:comments, @reflection.comments)
    assign(:comment, @reflection.comments.new)
    render
    rendered.should_not match(/<div class=\"main-content\">\s*<p class=\"fl-right alert alert-admin\">\s*<strong>Moderate:<\/strong>/)
  end

  it "does not render the moderation tools for reflection if not logged in" do
    @view.stub!(:signed_in?).and_return(false)
    assign(:conversation, @reflection.conversation)
    assign(:reflection, @reflection)
    assign(:comments, @reflection.comments)
    assign(:comment, @reflection.comments.new)
    render
    rendered.should_not match(/<div class=\"main-content\">\s*<p class=\"fl-right alert alert-admin\">\s*<strong>Moderate:<\/strong>/)
  end
end
