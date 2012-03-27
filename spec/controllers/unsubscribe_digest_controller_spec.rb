require 'spec_helper'

describe UnsubscribeDigestController do

  describe 'GET: confirm' do

    it "assigns the person to @person" do
      person = mock_model(Person)
      Person.should_receive(:find).with('27').and_return(person)
      get :unsubscribe_me, id: '27'
      assigns(:person).should == person
    end

  end

  describe "PUT: #remove_from_digest" do
    let(:person) { mock_model(Person) }

    before do
      person.stub(:unsubscribe_from_daily_digest)
      Person.should_receive(:find).with('27').and_return(person)
      put :remove_from_digest, id: '27'
    end

    it "unsubscribes the person from the daily digest", :pending => 'broke during rails3 upgrade' do
      person.should have_received(:unsubscribe_from_daily_digest)
    end

    it "redirects back to the home page" do
      response.should redirect_to(root_path)
    end

  end

end
