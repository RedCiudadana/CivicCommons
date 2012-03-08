require 'spec_helper'

describe "reflections/new.html.erb" do
  before(:each) do
    assign(:reflection, stub_model(Reflection,
      :title => "MyString",
      :details => "MyText"
    ).as_new_record)
  end

  it "renders new reflection form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => reflections_path, :method => "post" do
      assert_select "input#reflection_title", :name => "reflection[title]"
      assert_select "textarea#reflection_details", :name => "reflection[details]"
    end
  end
end
