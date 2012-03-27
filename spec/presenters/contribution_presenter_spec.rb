require 'spec_helper'

describe ContributionPresenter do

  before :all do
    # uncommnent these lines when working on these tests
    # stub_request(:put, /^http\:\/\/s3\.amazonaws\.com\/.*\/images\//).to_return(:status => 200, :body => "", :headers => {})
    # issue = Factory.create(:issue, name: 'Issue Title')
    # @issue_contribution = Factory.build(:issue_contribution, issue: issue)
    # conversation = Factory.create(:conversation, title: 'Conversation Title')
    # @conversation_contribution = Factory.build(:contribution, conversation: conversation)
  end

  context "creation", :pending => 'broke during rails3 upgrade' do
    it "requires a collection of objects" do
      lambda { ContributionPresenter.new }.should raise_error
      lambda { ContributionPresenter.new(@issue_contribution) }.should_not raise_error
      lambda { ContributionPresenter.new(@conversation_contribution) }.should_not raise_error
    end
  end

  context "accessing", :pending => 'broke during rails3 upgrade' do
    it 'will return the title of the conversation or issue' do
      presenter = ContributionPresenter.new(@conversation_contribution)
      presenter.parent_title.should == 'Conversation Title'
      presenter = ContributionPresenter.new(@issue_contribution)
      presenter.parent_title.should == 'Issue Title'
    end

    it 'will return the class of the parent in lowercase', :pending => 'broke during rails3 upgrade' do
      presenter = ContributionPresenter.new(@conversation_contribution)
      presenter.parent_type.should == 'conversation'
      presenter = ContributionPresenter.new(@issue_contribution)
      presenter.parent_type.should == 'issue'
    end
  end

end
