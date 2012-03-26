require 'spec_helper'

describe "reflections/show.html.erb" do
  before(:each) do
    @reflection = assign(:reflection, stub_model(Reflection,
      :title => "Title",
      :details => "MyText",
      :created_at => "2012-03-17 12:34:56"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Title/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
  end
end
