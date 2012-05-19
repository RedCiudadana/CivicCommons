require 'spec_helper'

describe 'layouts/_opportunity_header.html.erb' do
  def mock_conversation(attributes = {})
    @mock_conversation ||= mock_model(Conversation, attributes).as_null_object
  end

  def mock_managed_issue(attributes = {})
    @mock_managed_issue ||= mock_model(ManagedIssue, attributes).as_null_object
  end
  
  
  before(:each) do
    @conversation = mock_conversation
    stub_template('/subscriptions/_subscription.html.erb' => 'subscription-template-here')
  end

  context "standard_banner_image" do
    it "should not display banner if there is no managed_issue" do
      @conversation.stub_chain(:managed_issue,:first).and_return(nil)
      render :partial => 'layouts/opportunity_header'
      rendered.should_not have_selector('div.project-banner')
    end
    it "should display banner image if there is managed issue and there is standard_banner_image" do
      managed_issue = mock_managed_issue(:standard_banner_image => double(:exists? => true, :url => 'http://banner-image.test'))
      @conversation.stub_chain(:managed_issue,:first).and_return(managed_issue)
      render :partial => 'layouts/opportunity_header'
      rendered.should have_selector('div.project-banner')
    end
    it "should display banner image but not display banner image text if it doesn't exist" do
      managed_issue = mock_managed_issue(:standard_banner_image_title => 'standard image title here',:standard_banner_image => double(:exists? => true, :url => 'http://banner-image.test'))
      @conversation.stub_chain(:managed_issue,:first).and_return(managed_issue)
      render :partial => 'layouts/opportunity_header'
      rendered.should have_selector('div.project-banner')
      rendered.should have_content('standard image title here')
    end
    it "should display banner image and banner image text if it exists" do
      managed_issue = mock_managed_issue(:standard_banner_image => double(:exists? => true, :url => 'http://banner-image.test'))
      @conversation.stub_chain(:managed_issue,:first).and_return(managed_issue)
      render :partial => 'layouts/opportunity_header'
      rendered.should have_selector('div.project-banner')
      rendered.should_not have_content('standard image title here')
      
    end
  end

end
