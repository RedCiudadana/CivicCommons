require 'spec_helper'

describe AvatarHelper do

  before(:each) do
    @me = FactoryGirl.build(:normal_person, :first_name => "My", :last_name => "Self", :avatar_url => "http://avatar_url", :avatar_cached_image_url => '')
    @me.id = 1
    @registered_user = FactoryGirl.build(:registered_user_with_avatar, :first_name => "Someone", :last_name => "Else", :id => 13, :avatar_url => '/images/avatar_70.gif')
    @registered_user.id = 13
    @invalid_registered_user = FactoryGirl.build(:registered_user_with_avatar, :first_name => "Someone", :last_name => "Bad")
    @invalid_registered_user.id = 4
    @amazon_config = YAML.load_file( File.join(Rails.root, "config", "amazon_s3.yml"))[Rails.env]
  end

  context "link to profile" do

    it "should link to my private page" do
      helper.stub(:current_person).and_return(@me)
      helper.link_to_profile(@me) do
        "blah"
      end.should =~ /\<a href="\S*\/user\/1" title="My Self">blah<\/a>/i
    end

    it "should like to go to a persons public page" do
      helper.stub(:current_person).and_return(@registered_user)
      helper.link_to_profile(@registered_user) do
        "blah"
      end.should =~ /\<a href="\S*\/user\/13" title="Someone Else">blah<\/a>/i

    end

  end

  context "text profile" do

    it "should display a users name with a link" do
      helper.stub(:current_person).and_return(@me)
      @registered_user.avatar.stub(:url).and_return("http://avatar_url")

      helper.text_profile(@registered_user).should =~ /\<a href="\S*\/user\/13" title="Someone Else">Someone Else<\/a>/i
    end

  end

  context "profile image" do

    it "renders the AvatarService" do
      AvatarService.should_receive(:avatar_image_url)
      helper.profile_image(@me, 80)
    end

  end

  context "local profile image" do

    it "should display a profile image with the default size" do
      helper.profile_image(@me).should =~ /<img alt="My Self" class="callout" height="20" src="\S*" title="My Self" width="20" \/>/i
    end

    it "should display a profile image with a size of 80" do
      helper.profile_image(@me, 80).should match(/80/)
    end

  end

  context "member profile" do
    it "calls avatar profile" do
      view.stub(:avatar_profile).with(@me, 40, 'callout').and_return('my member profile')
      helper.member_profile(@me).should =~ /my member profile/
    end
  end

end
