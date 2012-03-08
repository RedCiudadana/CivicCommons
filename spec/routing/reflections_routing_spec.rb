require "spec_helper"

describe ReflectionsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/reflections" }.should route_to(:controller => "reflections", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/reflections/new" }.should route_to(:controller => "reflections", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/reflections/1" }.should route_to(:controller => "reflections", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/reflections/1/edit" }.should route_to(:controller => "reflections", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/reflections" }.should route_to(:controller => "reflections", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/reflections/1" }.should route_to(:controller => "reflections", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/reflections/1" }.should route_to(:controller => "reflections", :action => "destroy", :id => "1")
    end

  end
end
