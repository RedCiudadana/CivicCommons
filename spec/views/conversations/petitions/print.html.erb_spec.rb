require 'spec_helper'

describe '/petitions/print.html.erb' do
  before(:each) do
    @petition = FactoryGirl.create(:petition)
    assign :petition, @petition
  end

  it "should show the Petition title" do
    render
    rendered.should contain @petition.title
  end

  it "should show the Petition description" do
    render
    rendered.should contain @petition.description
  end

  it "should show the message when there are no signers" do
    assign :petition, FactoryGirl.create(:unsigned_petition)
    render
    rendered.should contain 'There have been no signatures so far.'
  end
end
