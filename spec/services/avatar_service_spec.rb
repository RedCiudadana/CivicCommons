require 'spec_helper'

module Services

  describe AvatarService do

    before(:each) do
      @person = FactoryGirl.create(:registered_user, :twitter_username => "civiccommons")
    end



    context "Determining avatar url" do
      context "by order of priorities" do
        before(:each) do
          AvatarService.stub!(:create_email_hash).and_return(5)
        end

        it "should return their uploaded avatar picture first" do
          @person = FactoryGirl.create(:registered_user_with_avatar, :twitter_username => "civiccommons")
          @person.update_attributes(:twitter_username => 'twitterusername')
          @person.stub_chain(:authentications, :present?).and_return(:true)

          AvatarService.stub!(:gravatar_available?).and_return(true)
          avatar_url = AvatarService.avatar_image_url(@person)
          avatar_url.should match(/avatars/)
        end
        it "should return their facebook profile pic second" do
          @person.stub!(:avatar?).and_return(false)
          @person.update_attributes(:twitter_username => 'twitterusername')
          @person.stub_chain(:authentications, :present?).and_return(true)
          @person.stub_chain(:authentications, :first, :uid).and_return(1)
          AvatarService.stub!(:gravatar_available?).and_return(true)

          avatar_url = AvatarService.avatar_image_url(@person)
          avatar_url.should == "https://graph.facebook.com/1/picture"
        end
        it "should return their twitter profile pic third" do
          @person.stub!(:avatar?).and_return(false)
          @person.stub_chain(:authentications, :present?).and_return(false)
          @person.update_attributes(:twitter_username => 'twitterusername')
          AvatarService.stub!(:gravatar_available?).and_return(true)

          avatar_url = AvatarService.avatar_image_url(@person)
          avatar_url.should == "http://api.twitter.com/1/users/profile_image/twitterusername"
        end
        it "should return their gravatar pic fourth" do
          @person.stub!(:avatar?).and_return(false)
          @person.update_attributes(:twitter_username => 'twitterusername')
          @person.stub_chain(:authentications, :present?).and_return(false)
          @person.stub_chain(:twitter_username, :present?).and_return(false)
          AvatarService.stub!(:gravatar_available?).and_return(true)

          avatar_url = AvatarService.avatar_image_url(@person)
          avatar_url.should == "http://gravatar.com/avatar/5?d=404"
        end
        it "should return a default picture last" do
          @person.stub!(:avatar?).and_return(false)
          @person.update_attributes(:twitter_username => 'twitterusername')
          @person.stub_chain(:authentications, :present?).and_return(false)
          @person.stub_chain(:twitter_username, :present?).and_return(false)
          AvatarService.stub!(:gravatar_available?).and_return(false)

          avatar_url = AvatarService.avatar_image_url(@person)
          avatar_url.should match(/http:\/\/s3.amazonaws.com\/.*\/avatars\/default\/avatar_70.gif/i)
        end
      end

      it "When a person has linked their Facebook account, returns a FB graph url" do
        @person.stub_chain(:authentications, :empty?).and_return(false)
        @person.stub_chain(:authentications, :first, :uid).and_return(1)
        avatar_url = AvatarService.avatar_image_url(@person)
        avatar_url.should == "https://graph.facebook.com/1/picture"
      end

      it "When a person has not linked their Facebook account, but the person has entered a Twitter Username, returns Twitter url" do
        @person.stub_chain(:authentications, :empty?).and_return(true)
        avatar_url = AvatarService.avatar_image_url(@person)
        avatar_url.should == "http://api.twitter.com/1/users/profile_image/civiccommons"
      end

      it "When a person does not have FB linked, or a Twitter username, checks if the user has a gravatar for their email, returns Gravatar url" do
        @person.update_attributes(:twitter_username => nil)
        AvatarService.should_receive(:gravatar_available?).and_return(true)
        AvatarService.should_receive(:create_email_hash).and_return(5)
        avatar_url = AvatarService.avatar_image_url(@person)
        avatar_url.should == "http://gravatar.com/avatar/5?d=404"
      end

      it "When a person does not have a FB linked, Twitter username, or Gravatar, defaults to the local CC avatar" do
        @person.update_attributes(:twitter_username => nil)
        AvatarService.should_receive(:gravatar_available?).and_return(false)
        avatar_url = AvatarService.avatar_image_url(@person)
        avatar_url.should match(/http:\/\/s3.amazonaws.com\/.*\/avatars\/default\/avatar_70.gif/i)
      end

    end

    context "Updating person's avatar url" do

      it "Saves the url for the person" do
        AvatarService.update_avatar_url_for(@person)
        @person.reload
        @person.avatar_url.should == AvatarService.avatar_image_url(@person)
      end

    end

  end
end
