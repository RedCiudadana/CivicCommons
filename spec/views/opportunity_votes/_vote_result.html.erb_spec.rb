require 'spec_helper'

describe 'opportunity_votes/_vote_result.html.erb' do
  def stub_person
    @stub_person ||= stub_model(Person).as_null_object
  end
  def stub_vote
    @stub_vote ||= stub_model(Vote,:created_at => Time.now,:person => stub_person).as_null_object
  end
  
  before(:each) do
    stub_template('/opportunity_votes/_result_bars' => 'rendering result_bars')
    @vote = stub_vote
  end

  context "show_progress_now? is true" do
    before(:each) do
      @vote.stub!(:show_progress_now?).and_return(true)
    end
    it "should display the results" do
      render
      rendered.should have_content 'Your vote results are marked in blue'
      rendered.should have_content 'rendering result_bars'
    end
  end
  context "show_progress_now? is false" do
    before(:each) do
      @vote.stub!(:show_progress_now?).and_return(false)
    end
    it "should not display the results" do
      render
      rendered.should_not have_content 'rendering result_bars'
    end
    it "should display the end date" do
      render
      rendered.should have_content 'Check back at the end of the day of'
    end
  end

end
