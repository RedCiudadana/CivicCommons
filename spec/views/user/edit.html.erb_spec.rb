require 'spec_helper'
describe '/user/edit.html.erb' do
  def stub_person(stubs = {})
    stub_model(Person,
      { :name => 'john doe',
        :bio => 'biohere',
        :zip_code => 1234,
        :avatar_cached_image_url => 'http://www.example.com/some_image.jpg'
      }.merge(stubs)
    )
  end

  def stub_organization(stubs ={})
    stub_model(Organization, stubs).as_null_object
  end

  def content_for(name)
    view.instance_variable_get(:@_content_for)[name]
  end

  def given_a_person_with_facebook_authentication
    @person = stub_person(:facebook_authenticated? => true)
    view.stub(:current_person).and_return(@person)
  end

  def given_a_person_without_facebook_authentication
    @person = stub_person(:facebook_authenticated? => false)
    view.stub(:current_person).and_return(@person)
  end

  def given_an_organization
    @person = stub_person(:is_organization? => true)
    view.stub(:current_person).and_return(@person)
  end

  context "profile picture" do

    it "should display profile image" do
      given_a_person_with_facebook_authentication
      view.should_receive(:profile_image)
      render
    end

    context "for users" do
      before(:each) do
        given_a_person_without_facebook_authentication
      end

      it "should display 'Remove Photograph' if the user has an avatar" do
        @person.stub(:avatar? => true)
        render
        content_for(:main_body).should contain "Remove Photograph"
      end

      it "should not display 'Remove Photograph' if user has no avatar" do
        @person.stub(:avatar? => false)
        render
        content_for(:main_body).should_not contain "Remove Photograph"
      end

      it "should display 'Your Photograph'" do
        render
        content_for(:main_body).should contain "Your Photograph"
      end

      it "should display 'Current Photograph' if the user has an avatar" do
        @person.stub(:avatar? => true)
        render
        content_for(:main_body).should contain "Current Photograph"
      end
    end

    context "for organizations" do
      before(:each) do
        given_an_organization
      end

      it "should display 'Remove Logo' if the organization has an avatar" do
        @person.stub(:avatar? => true)
        render
        content_for(:main_body).should contain "Remove Logo"
      end

      it "should not display 'Remove Logo' if organization has no avatar" do
        @person.stub(:avatar? => false)
        render
        content_for(:main_body).should_not contain "Remove Logo"
      end

      it "should display 'Your Logo'" do
        render
        content_for(:main_body).should contain "Company Logo"
      end

      it "should display 'Current Logo' if the organization has an avatar" do
        @person.stub(:avatar? => true)
        render
        content_for(:main_body).should contain "Current Logo"
      end
    end
  end

  context "Link to Facebook" do

    before(:each) do
      view.stub(:profile_image).and_return('')
    end

    it "should not display 'connect with facebook' if user is an organization" do
      given_an_organization
      render
      content_for(:main_body).should_not have_selector 'a.connectacct-link.facebook-auth', :content => "Connect with Facebook"
    end

    it "should display 'Connect with facebook' button if the user is not authenticated with Facebook" do
      given_a_person_without_facebook_authentication
      render
      content_for(:main_body).should have_selector 'a.connectacct-link.facebook-auth', :content => "Connect with Facebook"
    end

    it "should display 'unlink facebook' button if the user has linked the account with Facebook" do
      given_a_person_with_facebook_authentication
      render
      content_for(:main_body).should have_selector 'a.connectacct-link.facebook-auth.disconnect-fb', :content => "Unlink from Facebook"
    end

    context "Password text fields" do
      it "should not be displayed when user has linked to Facebook" do
        given_a_person_with_facebook_authentication
        render
        content_for(:main_body).should_not have_selector 'input#person_password'
        content_for(:main_body).should_not have_selector 'input#person_password_confirmation'
      end

      it "should be displayed when user has linked to Facebook" do
        given_a_person_without_facebook_authentication
        render
        content_for(:main_body).should have_selector 'input#person_password'
        content_for(:main_body).should have_selector 'input#person_password_confirmation'
      end
    end

  end

  context "Form field labels" do
    context "for users" do
      before(:each) do
        given_a_person_without_facebook_authentication
      end

      it "should display 'Tell us a little about yourself' for the bio field label" do
        render
        content_for(:main_body).should contain 'Tell us a little about yourself'
      end

      it "should display 'Your Name' for the name field label" do
        render
        content_for(:main_body).should contain 'Your Name'
      end
    end

    context "for organizations" do
      before(:each) do
        given_an_organization
      end

      it "should display 'Tell us about your company' for the bio field label" do
        render
        content_for(:main_body).should contain 'Tell us about your company'
      end

      it "should display 'Name of Organization' for the name field label" do
        render
        content_for(:main_body).should contain 'Name of Organization'
      end
    end
  end

end
