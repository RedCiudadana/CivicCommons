require 'spec_helper'

describe 'opportunity_votes/show.html.erb' do
  def stub_person
    @stub_person ||= stub_model(Person, :avatar_image_url => "avatar_image_url").as_null_object
  end

  def stub_vote
    @stub_vote ||= stub_model(Vote,:created_at => Time.now,:person => stub_person).as_null_object
  end

  before(:each) do
    # stub_template('opportunity_votes/_vote_layout.html' => '')
    stub!(:current_person).and_return(stub_person)
    stub_template('opportunity_votes/_select_options_form' => 'rendering select_options_form')
    stub_template('opportunity_votes/_vote_result' => 'rendering vote_result')
    stub_template('opportunity_votes/_vote_hidden_result' => 'rendering vote_hidden_result')
    stub!(:member_profile).and_return('')
    stub!(:text_profile).and_return('')
    VoteProgressService.stub!(:new).and_return('')
    @vote = stub_vote
    login_user
  end

  context "allowed to vote" do
    it "should render opportunity_votes/select_options_form " do
      @vote_response_presenter = double(:allowed? => true)
      render
      rendered.should have_content('rendering select_options_form')
    end
  end
  context "not allowed to vote" do
    context "if show progress is set to true" do
      it "should render opportunity_votes/vote_result" do
        @vote_response_presenter = double(:allowed? => false)
        @vote.stub!(:show_progress?).and_return(true)
        render
        rendered.should have_content('rendering vote_result')
      end
    end
    context "if show progress is NOT set to true" do
      it "should render opportunity_votes/vote_hidden_result" do
        @vote_response_presenter = double(:allowed? => false)
        @vote.stub(:show_progress?).and_return(false)
        render
        rendered.should have_content('rendering vote_hidden_result')
      end
    end
  end


end
