require 'spec_helper'

# A mock for the Embedly service.
# WebMock requires us to know which URLs are called from within the gem.
# Is it better to mock the API interface or mock the API internals?
# This approach mocks the API.
class MockEmbedly
  def initialize(json)
    @json = json
  end

  def objectify(opts = {})
    return Array[self]
  end

  def marshal_dump
    EmbedlyService.parse_raw(@json)
  end
end

describe EmbedlyService do

  before(:each) do
    stub_request(:get, /http:\/\/pro\.embed\.ly/).to_return(:body => File.open("#{Rails.root}/test/fixtures/embedly/youtube.json"), :status => 200)
  end

  describe "EmbedlyService#fetch(url)" do

    context "Success" do

      it "should pass all options through to Embedly" do

        url = 'http://www.youtube.com/watch?v=djtNtt8jDW4'
        opts = {
          :maxwidth => 100,
          :maxheight => 100,
        }

        mock_embedly = mock('embedly')
        mock_embedly.should_receive(:objectify).once.with(hash_including({url: url}))

        embedly = EmbedlyService.new(mock_embedly)
        embedly.fetch(url, opts)

      end

      it "retrieve embedly object given a valid YouTube url" do

        # These two lines use our internal mock
        json = fixture_content('embedly/youtube.json')
        embedly = EmbedlyService.new(MockEmbedly.new(json))

        # This line uses WebMock
        #embedly = EmbedlyService.new

        embedly.fetch('http://www.youtube.com/watch?v=djtNtt8jDW4')

        embedly.error.should be_nil
        embedly.properties.should_not be_nil

        embedly.properties.should have_key(:original_url)
        embedly.properties[:original_url].should == 'http://www.youtube.com/watch?v=djtNtt8jDW4'
        embedly.properties.should have_key(:url)
        embedly.properties[:url].should == 'http://www.youtube.com/watch?v=djtNtt8jDW4'
        embedly.properties.should have_key(:oembed)
        embedly.properties[:oembed].should be_instance_of Hash
      end

      describe "EmbedlyService#fetch_and_merge_params!(params)" do

        before(:each) do
          @hash = {:contribution => {:url => 'http://www.youtube.com/watch?v=djtNtt8jDW4'}}
          @embedly = EmbedlyService.new
          @embedly.fetch_and_merge_params!(@hash)
        end

        it "sets embedly_type to type returned from embedly", :pending => 'broke during rails3 upgrade' do
          @hash[:contribution][:embedly_type].should == 'video'
        end

        it "sets embedly_code to the raw json returned from embedly", :pending => 'broke during rails3 upgrade' do
          @hash[:contribution][:embedly_code].should be_an_instance_of(String)
        end

        it "returns true if able to connect to embedly", :pending => 'broke during rails3 upgrade' do
          @embedly.fetch_and_merge_params!(@hash).should be_true
        end

      end

      describe "EmbedlyService#fetch_ane_update_attributes(contribution)", :pending => 'broke during rails3 upgrade' do

        before(:each) do
          @contribution = Factory.create(:embedly_contribution, url: 'http://www.youtube.com/watch?v=ukuERsvfDMU')
          @embedly = EmbedlyService.new
          @boolean = @embedly.fetch_and_update_attributes(@contribution)
        end

        it "returns true if able to connect and retrieve information from embed.ly" do
          @boolean.should be_true
        end

        it "sets the contribution.embedly_code attribute to embed.ly json string" do
          @contribution.embedly_code.should be_an_instance_of(String)
        end

      end

    end

    context "Unsuccessful" do

      #TODO Figure out how to mock the logger and test it
      it "return nil properties and log if embedly is down" do

        mock_embedly = mock('embedly')
        mock_embedly.stub(:objectify).and_raise(StandardError)

        embedly = EmbedlyService.new(mock_embedly)
        embedly.fetch('http://www.youtube.com/watch?v=djtNtt8jDW4')
        embedly.properties.should be_nil
        embedly.error.should_not be_nil
      end

      #TODO Figure out how to mock the logger and test it
      it "return nil properties and log if embedly pro key is bad" do

        Civiccommons::Config.embedly['key'] = "garbage"
        mock_embedly = mock('embedly')
        mock_embedly.stub(:objectify).and_raise(StandardError)

        embedly = EmbedlyService.new(mock_embedly)
        embedly.fetch('http://www.youtube.com/watch?v=djtNtt8jDW4')
        embedly.properties.should be_nil
        embedly.error.should_not be_nil
      end

      #TODO Figure out how to mock the logger and test it
      it "return an error if url is invalid" do

        json = fixture_content('embedly/bad_url.json')
        embedly = EmbedlyService.new(MockEmbedly.new(json))

        embedly.fetch('garbage url')
        embedly.properties.should be_nil
        embedly.error.should_not be_nil
      end

    end

    # This set of tests exists simply to verify the accuracy of our fixtures
    # These tests should not be run normally, they are very slow and depend
    # on a live connection to embedly
    #context "Live connection to Embedly" do

      #before(:all) do
        #WebMock.allow_net_connect!
      #end

      #after(:all) do
        #WebMock.disable_net_connect!
      #end

      #let(:embedly) { EmbedlyService.new }

      #it "retrieve embedly object given a valid YouTube url" do
        #embedly.fetch('http://www.youtube.com/watch?v=djtNtt8jDW4')
        #embedly.properties.should have_key(:original_url)
        #embedly.fetch('http://www.youtube.com/watch?v=djtNtt8jDW4&some=other&garbage=data')
        #embedly.properties.should have_key(:url)
        #embedly.properties[:url].should == 'http://www.youtube.com/watch?v=djtNtt8jDW4'
        #embedly.properties.should have_key(:oembed)
        #embedly.properties[:oembed].should be_instance_of Hash
        #embedly.error.should be_nil
      #end

  end

  describe "EmbedltService#parse_raw(data)" do

    it "should properly parse data from an EmbedlyContribution" do
      contrib = Factory.build(:embedly_contribution)
      contrib.embedly_code = fixture_content('embedly/flickr.json')
      data = EmbedlyService.parse_raw(contrib)
      data.should_not be_empty
      data.should have_key(:embeds)

      embedly = EmbedlyService.new.load(contrib)
      embedly.properties.should_not be_empty
      embedly.properties.should have_key(:embeds)
    end

    it "should properly parse raw data" do
      data = EmbedlyService.parse_raw(fixture_content('embedly/flickr.json'))
      data.should_not be_empty
      data.should have_key(:embeds)
      data.should have_key(:images)
      data[:images].should be_instance_of(Array)
      data[:images].should_not be_empty
      data[:images][0].should be_instance_of(Hash)
      data[:images][0].should have_key(:url)

      embedly = EmbedlyService.new.load(fixture_content('embedly/flickr.json'))
      embedly.properties.should_not be_empty
      embedly.properties.should have_key(:embeds)
    end

    it "should return an empty hash when passed invalid JSON" do
      data = EmbedlyService.parse_raw('garbage')
      data.should be_empty

      embedly = EmbedlyService.new.load('garbage')
      embedly.properties.should be_empty
    end

  end

  describe "HTML helpers" do

    context "self.to_embed(embedly)" do

      context "success" do

        it "should return valid HTML code for a photo URL" do
          html = EmbedlyService.to_embed(fixture_content('embedly/flickr.json'))
          html.should =~ /^<img/
          html.should =~ /\s+src="http:\/\/farm6.static\.flickr\.com\/5216\/5387288109_4046bd10e1\.jpg"/
          html.should =~ /\s+height="324"/
          html.should =~ /\s+width="500"/
          html.should =~ /\s+title="The Start"/
          html.should =~ /\s+alt="Poster #19: &quot;The Start&quot; Created by: Tom Sawyer Community: North Royalton From the Artist: &quot;Even something as simple as a &quot;Hi&quot; can make someone's day&quot;."/
          html.should =~ /\s*\/>$/
        end

        it "should return valid HTML code for a video URL" do
          html = EmbedlyService.to_embed(fixture_content('embedly/youtube.json'))
          html.should =~ /^<object width="550" height="334">/
          html.should =~ /<param name="movie" value="http:\/\/www\.youtube\.com\/v\/onUd7aZhu9g\?version=3"><\/param>/
          # and possibly several more...

          html = EmbedlyService.new.load(fixture_content('embedly/youtube.json')).to_embed
          html.should =~ /^<object width="550" height="334">/
          html.should =~ /<param name="movie" value="http:\/\/www\.youtube\.com\/v\/onUd7aZhu9g\?version=3"><\/param>/
        end

        it "should return valid HTML code for a rich URL" do
          html = EmbedlyService.to_embed(fixture_content('embedly/google_map.json'))
          html.should =~ /^<iframe width="425" height="350"/
          # and possibly several more...

          html = EmbedlyService.new.load(fixture_content('embedly/google_map.json')).to_embed
          html.should =~ /^<iframe width="425" height="350"/
        end

        it "should return valid HTML code for a link URL" do
          html = EmbedlyService.to_embed(fixture_content('embedly/unknown.json'))
          html.should =~ /^<a/
          html.should =~ /\s+href=\"http:\/\/www\.theciviccommons\.com\/issues\/14\/\?from=statebudget\"/
          html.should =~ /\s+title=\"The Ohio State Budget\"/
          html.should =~ /\s*>The Ohio State Budget<\/a>$/
        end

        context "thumbnail generation" do

          it "should return a valid HTML img tag when at least one image is present" do
            html = EmbedlyService.to_thumbnail(fixture_content('embedly/flickr.json'))
            html.should =~ /^<img/
            html.should =~ /\s+src="http:\/\/farm6\.static\.flickr\.com\/5216\/5387288109_4046bd10e1_t\.jpg"/
            html.should =~ /\s+height="65"/
            html.should =~ /\s+width="100"/
            html.should =~ /\s+title="The Start"/
            html.should =~ /\s+alt="Poster #19: &quot;The Start&quot; Created by: Tom Sawyer Community: North Royalton From the Artist: &quot;Even something as simple as a &quot;Hi&quot; can make someone's day&quot;."/
            html.should =~ /\s*\/>$/

            html = EmbedlyService.to_thumbnail(fixture_content('embedly/rubyonrails.json'))
            html.should =~ /^<img/
            html.should =~ /\s+src="http:\/\/rubyonrails.org\/images\/applications\/twitter.jpg"/
            html.should =~ /\s+height="110"/
            html.should =~ /\s+width="175"/
            html.should =~ /\s+title="Ruby on Rails"/
            html.should =~ /\s+alt="&quot;Ruby on Rails is a breakthrough in lowering the barriers of entry to programming. Powerful web applications that formerly might have taken weeks or months to develop can be produced in a matter of days.&quot;-Tim O'Reilly, Founder of O'Reilly Media Read more quotes &quot;Rails&quot;, &quot;Ruby on Rails&quot;, and the Rails logo are registered trademarks of David Heinemeier Hansson."/
            html.should =~ /\s*\/>$/
          end

          it "should return nil when no thumbnail is present" do
            html = EmbedlyService.to_thumbnail(fixture_content('embedly/google.json'))
            html.should be_nil
          end

          it "should return nil when the image array is empty" do
            html = EmbedlyService.to_thumbnail(fixture_content('embedly/no_images.json'))
            html.should be_nil
          end

          context "maxwidth" do

            it "should return the widest image when maxwidth is not set" do
              html = EmbedlyService.to_thumbnail(fixture_content('embedly/flickr.json'))
              html.should =~ /\s+src="http:\/\/farm6\.static\.flickr\.com\/5216\/5387288109_4046bd10e1_t\.jpg"/
              html.should =~ /\s+height="65"/
              html.should =~ /\s+width="100"/
            end

            it "should return the widest image when maxwidth is greater than biggest image width" do
              maxwidth = 700
              html = EmbedlyService.to_thumbnail(fixture_content('embedly/flickr.json'), maxwidth)
              html.should =~ /\s+src="http:\/\/farm6\.static\.flickr\.com\/5216\/5387288109_4046bd10e1_t\.jpg"/
              html.should =~ /\s+height="65"/
              html.should =~ /\s+width="100"/
            end

            it "should return the widest image when width smaller than maxwidth" do
              maxwidth = 250
              html = EmbedlyService.to_thumbnail(fixture_content('embedly/flickr.json'), maxwidth)
              html.should =~ /\s+src="http:\/\/farm6\.static\.flickr\.com\/5216\/5387288109_4046bd10e1_t\.jpg"/
              html.should =~ /\s+height="65"/
              html.should =~ /\s+width="100"/
            end

            it "should scale the image when all images are wider than maxwidth" do
              maxwidth = 24
              html = EmbedlyService.to_thumbnail(fixture_content('embedly/flickr.json'), maxwidth)
              html.should =~ /\s+src="http:\/\/farm6\.static\.flickr\.com\/5216\/5387288109_4046bd10e1_t\.jpg"/
              html.should =~ /\s+height="15"/
              html.should =~ /\s+width="24"/
            end

          end

          context "Embedly or Fancybox" do

            it "should return embed code if the embed is less than max_embed_width" do
              maxwidth = 600
              html = EmbedlyService.to_embed_or_fancybox(fixture_content('embedly/youtube.json'), maxwidth)
              html.should =~ /^<object width="550" height="334">/
              html.should =~ /<param name="movie" value="http:\/\/www\.youtube\.com\/v\/onUd7aZhu9g\?version=3"><\/param>/
            end

            it "should return a thumbnail if the embed is larger than max_embed_width" do
              maxwidth = 250
              html = EmbedlyService.to_embed_or_fancybox(fixture_content('embedly/flickr.json'), maxwidth)
              html.should =~ /\s+src="http:\/\/farm6\.static\.flickr\.com\/5216\/5387288109_4046bd10e1_t\.jpg"/
              html.should =~ /\s+height="65"/
              html.should =~ /\s+width="100"/
            end

            # Changed our minds and decided to return an empty string instead
            #it "should return a link if there is no embed code and no image" do
              #html = EmbedlyService.to_embed_or_fancybox(fixture_content('embedly/no_images.json'))
              #html.should =~ /^<a/
              #html.should =~ /\s+href="http:\/\/www\.alfajango\.com\/blog\/track-jquery-ajax-requests-in-google-analytics\/"/
              #html.should =~ /\s+title=\"Track jQuery AJAX Requests in Google Analytics - Alfa Jango Blog\"/
              #html.should =~ /\s*>Track jQuery AJAX Requests in Google Analytics - Alfa Jango Blog<\/a>$/
            #end

            it "should return nil if there is no embed code and no image" do
              html = EmbedlyService.to_embed_or_fancybox(fixture_content('embedly/no_images.json'))
              html.should_not be_nil
              html.should be_empty
            end
          end

        end

      end

      context "failure" do

        it "should return nil when return type is error" do
          html = EmbedlyService.to_embed(fixture_content('embedly/bad_url.json'))
          html.should be_nil

          html = EmbedlyService.new.load(fixture_content('embedly/bad_url.json')).to_embed
          html.should be_nil
        end

        it "should return nil when given a bad parameter" do
          html = EmbedlyService.to_embed('garbage')
          html.should be_nil

          html = EmbedlyService.new.load('garbage').to_embed
          html.should be_nil
        end

      end

    end

  end

end
