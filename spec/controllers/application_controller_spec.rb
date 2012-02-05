require 'spec_helper'

#####################################################################
# require_ssl

class ApplicationControllerRequireSSL < ApplicationController
  before_filter :require_ssl
end

describe ApplicationControllerRequireSSL do
  controller(ApplicationControllerRequireSSL) do
    def index
      render :nothing => true
    end
  end

  before(:all) do
    @ssl_login = Civiccommons::Config.security['ssl_login']
    Civiccommons::Config.security['ssl_login'] = true
  end

  after(:all) do
    Civiccommons::Config.security['ssl_login'] = @ssl_login
  end

  it "should redirect to an SSL URL when SSL is not used" do
    get :index
    response.should be_redirect
    response.should redirect_to('https://test.host/stub_resources')
  end

end

#####################################################################
# require_ssl

class ApplicationControllerRequireNoSSL < ApplicationController
  before_filter :require_no_ssl
end

describe ApplicationControllerRequireNoSSL do
  controller(ApplicationControllerRequireNoSSL) do
    def index
      render :nothing => true
    end
  end

  before(:all) do
    @ssl_login = Civiccommons::Config.security['ssl_login']
    Civiccommons::Config.security['ssl_login'] = true
  end

  after(:all) do
    Civiccommons::Config.security['ssl_login'] = @ssl_login
  end

  it "should redirect to an SSL URL when SSL is not used" do
    request.env['HTTPS'] = 'on'
    get :index
    response.should be_redirect
    response.should redirect_to('http://test.host/stub_resources')
  end
  
  it "should call the require_no_ssl filter" do
    controller.should_receive(:require_no_ssl)
    get :index
  end

end

#####################################################################
# require_user

class ApplicationControllerRequireUser < ApplicationController
  before_filter :require_user
end

describe ApplicationControllerRequireUser do
  controller(ApplicationControllerRequireUser) do
    def index
      render :nothing => true
    end
  end

  it "should redirect when no user is present" do
    get :index
    response.should be_redirect
    response.should redirect_to('http://test.host/people/login')
  end

  it "should not redirect when a user is present" do
    sign_in Factory.create(:registered_user)
    get :index
    response.should_not be_redirect
  end

end

#####################################################################
# verify_admin

class ApplicationControllerVerifyAdmin < ApplicationController
  before_filter :verify_admin
end

describe ApplicationControllerVerifyAdmin do
  controller(ApplicationControllerVerifyAdmin) do
    def index
      render :nothing => true
    end
  end

  it "should redirect when no user is present" do
    get :index
    response.should be_redirect
    response.should redirect_to('http://test.host/people/login')
  end

  it "should redirect when a non-admin user is present" do
    user =  Factory.create(:registered_user)
    sign_in user
    get :index
    response.should be_redirect
    response.should redirect_to('http://test.host/people/login')
    sign_out user
  end

  it "should not redirect when an admin user is present" do
    user = Factory.create(:admin_person)
    sign_in user
    get :index
    response.should_not be_redirect
    sign_out user
  end

end