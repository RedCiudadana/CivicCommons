require "spec_helper"

describe OpportunitiesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { get: "/opportunities" }.should route_to(controller: "opportunities", action: "index")
      { get: "/opportunities/" }.should route_to(controller: "opportunities", action: "index")
    end

    it "recognizes and generates #show" do
      { get: "/opportunities/1" }.should route_to(controller: "opportunities", action: "show", :id => "1")
      { get: "/opportunities/slug" }.should route_to(controller: "opportunities", action: "show", :id => "slug")
    end

  end
end
