require 'spec_helper'

describe UserController do
  let(:user) do
    Factory.create(:normal_person)
  end

  def stub_person(stubs={})
    stub_model(Person, stubs)
  end

  def stub_organization(stubs ={})
    stub_model(Organization,stubs).as_null_object
  end
  
  context "before_filters" do
    it "should skip require_no_ssl filter on update" do
      controller.should_not_receive(:require_no_ssl)
      put :update, :id => 123
    end
    it "should skip require_no_ssl filter on edit" do
      controller.should_not_receive(:require_no_ssl)
      get :edit, :id => 123
    end
    it "should skip require_no_ssl filter on destroy_avatar" do
      controller.should_not_receive(:require_no_ssl)
      delete :destroy_avatar, :id => 123
    end
  end

  context "GET 'show'" do
    it "puts the user in a ProfilePresenter" do
      get :show, :id => user.cached_slug
      assigns(:user).should be_a ProfilePresenter
      assigns(:user).__getobj__.should == user
    end

    it "takes you to the community page if a user doesn't exist" do
      get :show, :id => 0
      response.should redirect_to(community_path)
    end
  end

  describe "PUT update" do
    context "as a registered user" do
      it "should update attributes" do
        person = Factory.create(:registered_user, zip_code: '11111')
        controller.stub!(:current_person).and_return(person)
        changes = person.attributes
        changes["zip_code"] = '55555'
        put :update, id: person.id, person: changes
        person.reload.zip_code.should == '55555'
      end
    end

    context "as an organization" do
      it "should update attributes" do
        organization = Factory.create(:organization, zip_code: '11111')
        controller.stub!(:current_person).and_return(organization)
        changes = organization.attributes
        changes["zip_code"] = '55555'
        put :update, id: organization.id, organization: changes
        organization.reload.zip_code.should == '55555'
      end
    end
  end

  context "POST destroy_avatar" do

    def given_user_with_facebook_authenticated_and_without_avatar
      @person = stub_person(:facebook_authenticated? => true, :avatar => false, :facebook_profile_pic_url => 'graph.facebook.com/1234/picture')
    end

    def given_user_without_facebook_authenticated
      @person = stub_person(:facebook_authenticated? => false)
    end

    before(:each) do
      controller.stub(:verify_ownership?).and_return(true)
    end

    it "should return the avatar if have not been authenticated with Facebook" do
      given_user_without_facebook_authenticated
      Person.stub(:find).and_return(@person)
      @person.stub(:save).and_return(true)

      delete :destroy_avatar, :id => "1234", :format => :js
      response.should contain "{\"avatarUrl\":\"/images/avatar_70.gif\"}"
    end

    it "should return the Avatar based on the AvatarService" do
      given_user_with_facebook_authenticated_and_without_avatar
      Person.stub(:find).and_return(@person)
      AvatarService.should_receive(:avatar_image_url).with(@person).and_return('http://avatar/url/here')
      @person.stub(:save).and_return(true)

      delete :destroy_avatar, :id => "1234", :format => :js
      response.should contain "{\"avatarUrl\":\"http://avatar/url/here\"}"
    end

    it "should return 500 if unable to save" do
      @person = stub_person
      Person.stub(:find).and_return(@person)
      @person.stub(:save).and_return(false)

      delete :destroy_avatar, :id => '1234', :format => :js
      response.status.should == 500
    end
  end

  context "POST join_as_member" do
    before(:each) do
      @person = stub_person
      controller.stub!(:current_person).and_return(@person)
      @organization = stub_organization
      Organization.stub!(:find).and_return(@organization)
    end
    it "should add the user to the organization's members" do
      @organization.should_receive(:join_as_member).with(@person)
      post :join_as_member, :id => '1234'
    end
    it "should render template membership_button " do
      @organization.stub!(:join_as_member).and_return(true)
      post :join_as_member, :id => '1234', :format => 'js'
      response.should render_template 'organizations/join_as_member'
    end
  end

  context "DELETE remove_membership" do
    before(:each) do
      @person = stub_person
      controller.stub!(:current_person).and_return(@person)
      @organization = stub_organization
      Organization.stub!(:find).and_return(@organization)
    end
    it "should remove the user from the organization's members" do
      @organization.should_receive(:remove_member).with(@person).and_return(true)
      delete :remove_membership, :id => '1234'
    end
    it "should render template membership_button" do
      @organization.stub!(:remove_member).and_return(true)
      delete :remove_membership, :id => '1234', :format => 'js'
      response.should render_template 'organizations/remove_membership'
    end
  end
end
