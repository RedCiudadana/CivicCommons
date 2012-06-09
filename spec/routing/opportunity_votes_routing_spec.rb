require "spec_helper"

describe OpportunityVotesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/conversations/1/votes" }.should route_to(:controller => "opportunity_votes", :conversation_id => '1', :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/conversations/1/votes/new" }.should route_to(:controller => "opportunity_votes", :conversation_id => '1', :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/conversations/1/votes/12" }.should route_to(:controller => "opportunity_votes", :conversation_id => '1', :action => "show", :id => "12")
    end

    it "recognizes and generates #create" do
      { :post => "/conversations/1/votes" }.should route_to(:controller => "opportunity_votes", :conversation_id => '1', :action => "create")
    end
  end
end
