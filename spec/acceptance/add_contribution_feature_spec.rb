require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

WebMock.allow_net_connect!
Capybara.default_wait_time = 30

feature "Add contribution", %q{
  As a registered user at The Civic Commons
  I want to add a contribution
  So that I can interact with the community

  Scenario:
} do

  let(:content) do
    'This is my contribution...'
  end
  let(:file_and_url_error_message) do
    "Woops! We only let you submit one link or file per contribution"
  end


  let(:contrib) { ContributionTool.new(page) }
  let(:convo_page) { ConversationPage.new(page) }
  let(:file_only_error_message) do
    "Sorry! You must also write a comment above when you upload a file."
  end

  let(:url) do
    # because of WebMock this URL will always be mocked to/from Embedly
    # /test/fixtures/embedly/youtube.json
    # /spec/support/stubbed_http_requests.rb
    'http://www.youtube.com/watch?v=djtNtt8jDW4'
  end

  let(:file_path) do
    'test/fixtures/cc_logos.pdf'
  end

  def contribution_tool
    contrib
  end
  background do

    login_as :person
    create_contribution
    self.conversation = contribution.conversation
  end
  scenario "Contribution tool is hidden by default", :js => true do
    goto_convo_page_for conversation
    contribution_tool.should_not be_visible
  end

  scenario "Contribution tool appears when a user posts to a conversation", :js => true do
    start_posting_to_conversation
    contribution_tool.should be_visible
  end

  scenario "Contribution tool appears when a user responds to a root-level contribution", :js => true do

    goto_convo_page_for conversation
    contrib.respond_to_link(contribution).click
    contrib.should be_visible
    contrib.should be_within_container convo_page.contribution_subthread(contribution)
  end

  scenario "Contribution tool appears when a user responds to a child contribution", :js => true do

    # Given a child contribution exists
    child = Factory.create(:contribution,
                           :override_confirmed => true,
                           :conversation => conversation,
                           :parent => contribution)

    convo_page = ConversationPage.new(page)
    convo_page.visit_node(conversation, child)
    sleep(1)

    contrib = ContributionTool.new(page)

    # When I click on the respond-to button
    contrib.respond_to_link(child).click     # need to see if the child is available to be clicked

    # Then I should see the contribution tool
    contrib.should be_visible

    # And it will appear as the last list element
    contrib.should be_within_container convo_page.contribution_subthread(contribution)
  end

  scenario "Contribution tool appears below all other contributions in the same thread", :js => true do
    contributions = create_some_nested_contributions

    contributions.each do |contribution|
      # Given I am on a conversation node permalink page
      convo_page = ConversationPage.new(page)
      convo_page.visit_node(conversation, contribution)
      sleep(2)
      contrib = ContributionTool.new(page)

      # When I click on the respond-to button
      contrib.respond_to_link(contribution).click

      # Then I should see the contribution tool
      contrib.should be_visible

      # And it will appear as the last list element
      contrib.should be_within_container convo_page.contribution_subthread(contribution)
    end
  end

  scenario "Contribution tool has all required elements", :js => true do
    convo_page = ConversationPage.new(page)
    convo_page.visit_page(conversation)
    contrib = ContributionTool.new(page)

    contrib.post_to_link.click
    contrib.content_field.should_not be_visible
    contrib.wysiwyg_editor.should be_visible
    contrib.add_url_link.should be_visible
    contrib.url_field.should_not be_visible
    contrib.add_file_link.should be_visible
    contrib.file_field.should_not be_visible
    contrib.submit_button.should be_visible
    contrib.cancel_link.should be_visible
    contrib.add_url_link.click
    contrib.url_field.should be_visible
    contrib.cancel_adding_url
    contrib.add_file_link.click
    contrib.file_field.should be_visible
 end

  scenario "Cancelling a contribution", :js => true do
    start_posting_to_conversation

    contrib.fill_in_content_field(content)
    contrib.cancel_link.click
    contrib.should_not be_visible
    convo_page.should_not have_content content
  end

  scenario "Posting only a comment", :js => true do
    start_posting_to_conversation

    contribution_tool.fill_in_content_field(content)
    contribution_tool.submit_button.click
    convo_page.should have_content(content)
    contribution_tool.wysiwyg_editor.should_not be_visible

  end

  scenario "Posting only a url", :js => true, :pending => 'broken during rails upgrade' do
    start_posting_to_conversation
    contrib.add_url url
    contrib.submit_button.click
    contrib.should have_css("a[href='#{url}']")
    contrib.should_not be_visible
  end

  scenario "Posting only a file is not allowed", :js => true do

    start_posting_to_conversation

    contrib.add_file file_path
    contrib.submit_button.click
    contrib.should be_visible

  end

  scenario "Posting a comment with a url", :js => true, :pending => 'broken during rails upgrade' do

    start_posting_to_conversation

    contrib.fill_in_content_field(content)
    contrib.add_url url
    contrib.submit_button.click
    convo_page.should have_content(content)
    contrib.should have_css("a[href='#{url}']")
    contrib.should_not be_visible

  end

  scenario "Posting a comment with a file", :js => true do
    start_posting_to_conversation

    contrib.fill_in_content_field(content)

    contrib.add_file file_path
    contrib.submit_button.click
    convo_page.should have_content(content)
    contrib.should have_link(logged_in_user.name)

  end

  def conversation= convo
    @conversation = convo
  end
  def conversation
    @conversation
  end

  def create_some_nested_contributions
    contributions = []
    2.times { contributions << create_subcontribution_for(contribution)}
    2.times { contributions << create_subcontribution_for(contributions.first)}
    contributions
  end
  def start_posting_to_conversation

    convo_page = ConversationPage.new(page)
    convo_page.visit_page(conversation)

    contribution_tool.post_to_link.click
  end
  def goto_convo_page_for conversation
    convo_page.visit_page conversation
  end
end
