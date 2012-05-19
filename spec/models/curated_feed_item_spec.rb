require 'spec_helper'

describe CuratedFeedItem do

  let(:params) do
    FactoryGirl.attributes_for(:curated_feed_item, curated_feed_id: 1)
  end

  context "validation" do

    it "creates a valid object" do
      CuratedFeedItem.new(params).should be_valid
    end

    it "requires a original_url" do
      params.delete(:original_url)
      CuratedFeedItem.new(params).should_not be_valid
    end

    it "requires a curated_feed_id" do
      params.delete(:curated_feed_id)
      CuratedFeedItem.new(params).should_not be_valid
    end

    it "sets pub_date when not provided" do
      params.delete(:pub_date)
      item = CuratedFeedItem.new(params)
      item.should be_valid
      item.pub_date.should_not be_blank
    end

  end

  context "objectify" do

    it "builds the raw data into an object model" do
      feed = CuratedFeedItem.new
      feed.raw = fixture_content('curated_feed_objectify.json')
      feed.objectify.provider_url.should == 'http://blog.cleveland.com/'
      feed.objectify.images.first.url.should == 'http://media.cleveland.com//avatars/img_5657t.jpg'
    end

  end

  context "Embedly" do

    before(:each) do
      @item = CuratedFeedItem.new
      @item.original_url = params[:original_url]
      @item.curated_feed_id = params[:curated_feed_id]
    end

    it "updates attributes on save" do
      pending 'resolve {:objectify=>["Server Issues"]}'
      stub_request(:get, /http:\/\/pro\.embed\.ly/).to_return(:body => fixture_content('curated_feed_objectify.json'), :status => 200)
      @item.save
      @item.provider_url.should_not be_blank
      @item.title.should_not be_blank
      @item.description.should_not be_blank
      @item.raw.should_not be_blank
    end

    it "prevents save on error" do
      stub_request(:get, /http:\/\/pro\.embed\.ly/).to_return(:body => fixture_content('curated_feed_error.json'), :status => 200)
      @item.save.should == false
      @item.errors.should_not be_empty
    end

  end

end
