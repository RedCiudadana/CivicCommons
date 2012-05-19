require 'spec_helper'

describe "reflections/index.html.erb" do
  before(:each) do
    #assign(:conversation,
      #stub_model(Conversation,
        #:title => "My Conversation",
        #:details => "My Conversation Detail"
      #).with(:issues) {nil}
    #)

    conversation = double("conversation", {:id => 21, 
      :name => "My Conversation", 
      :details => "My Conversation Details", 
      :issues => nil, 
      :reflection_participants => []})

    assign(:conversation, conversation)


    person = double("person")
    person.stub(:name => "James May")
    Person.stub(:find) {person}

    assign(:reflections, [
      stub_model(Reflection,
        :title => "Title",
        :details => "MyText",
        :owner => 2,
        :created_at => DateTime.now
      ),
      stub_model(Reflection,
        :title => "Title",
        :details => "MyText",
        :owner => 1,
        :created_at => DateTime.now
      )
    ])
  end

  it "renders a list of reflections" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "h3", :text => "Title".to_s, :count => 2
    
    rendered.should contain 'MyText'
  end
end
