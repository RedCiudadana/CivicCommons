require 'spec_helper'

describe "reflections/index.html.erb" do
  before(:each) do
    assign(:conversation,
      stub_model(Conversation,
        :title => "My Conversation",
        :details => "My Conversation Detail",
        :standard_issue => [],
      )
    )
    person = double("person")
    person.stub(:name => "James May")
    Person.stub(:find) {person}
    assign(:reflections, [
      stub_model(Reflection,
        :title => "Title",
        :details => "MyText",
        :owner => 2
      ),
      stub_model(Reflection,
        :title => "Title",
        :details => "MyText",
        :owner => 1
      )
    ])
  end

  it "renders a list of reflections" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "h3", :text => "Title".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "p", :text => "MyText".to_s, :count => 2
  end
end
