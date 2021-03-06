require 'spec_helper'

describe ContributionPresenter do

  before :all do
    stub_request(:put, /^http\:\/\/s3\.amazonaws\.com\/.*\/images\//).to_return(:status => 200, :body => "", :headers => {})
    issue = FactoryGirl.create(:issue, name: 'Issue Title')
    @issue_contribution = FactoryGirl.build(:issue_contribution, issue: issue)
    conversation = FactoryGirl.create(:conversation, title: 'Conversation Title')
    @conversation_contribution = FactoryGirl.build(:contribution, conversation: conversation)
  end

  context "creation" do
    it "requires a collection of objects" do
      lambda { ContributionPresenter.new }.should raise_error
      lambda { ContributionPresenter.new(@issue_contribution) }.should_not raise_error
      lambda { ContributionPresenter.new(@conversation_contribution) }.should_not raise_error
    end
  end

  context "accessing" do
    it 'will return the title of the conversation or issue' do
      presenter = ContributionPresenter.new(@conversation_contribution)
      presenter.parent_title.should == 'Conversation Title'
      presenter = ContributionPresenter.new(@issue_contribution)
      presenter.parent_title.should == 'Issue Title'
    end

    it 'will return the class of the parent in lowercase' do
      presenter = ContributionPresenter.new(@conversation_contribution)
      presenter.parent_type.should == 'conversation'
      presenter = ContributionPresenter.new(@issue_contribution)
      presenter.parent_type.should == 'issue'
    end
  end

end
