module CivicCommonsDriver
  include Database
  include Rails.application.routes.url_helpers
  @@available_pages = {}
  @@current_page = nil
  @@user = nil
  def self.available_pages
    @@available_pages
  end

  def self.set_current_page_to page, options={}
    return if page == :current
    raise "OH NOES NO PAGE FOR #{page}" unless @@available_pages.has_key?(page)
    self.current_page = @@available_pages[page].new options
  end


  def set_current_page_to page, options = {}
    CivicCommonsDriver.set_current_page_to page, options
  end

  def create_user(type, options={})
    FactoryGirl.create(type, options)
  end

  def login_as(type = :person, options={})
    goto :login
    self.user = create_user type, options
    login logged_in_user
  end
  def sign_out
    visit '/people/logout'
  end
  def log_back_in
    goto :login
    login logged_in_user
  end
  def newly_registered_user
    Person.last
  end

  def reload_logged_in_user
    self.user = database.find_user(logged_in_user)
  end
  def goto screen, options={}
    set_current_page_to screen, options
    current_page.goto
  end

  def goto_admin_page_as_admin
    login_as :admin
    goto :admin
  end

  def current_page
    @@current_page
  end

  def topic_i_added
    Topic.last
  end

  def submitted_topic
    Topic.find_by_name "WOOHOO!"
  end

  def the_current_page
    current_page
  end

  def create_contribution options={}
    self.contribution = FactoryGirl.create(:contribution_without_parent, options)
  end

  def contribution= contribution
    @@contribution = contribution
  end

  def contribution
    @@contribution
  end

  def conversation
    Conversation.last
  end

  def issue
    Issue.last
  end

  def user=(user)
    @@user =(user)
  end

  def logged_in_user
    @@user
  end

  def create_subcontribution_for contribution
    FactoryGirl.create(:contribution, :conversation=>contribution.conversation, :parent=> contribution)
  end
  def page_header
    @header = (@header || Header.new)
  end

  def method_missing(method, *args, &block)
    if current_page and current_page.respond_to? method
      current_page.send(method, *args, &block)
    else
      begin
        super
      rescue NameError
        raise "#{current_page} doesnt respond to #{method}"
      end
    end
  end
  :private

  def self.current_page= page
    @@current_page = page
  end
end


RSpec.configuration.include CivicCommonsDriver, :type => :acceptance
