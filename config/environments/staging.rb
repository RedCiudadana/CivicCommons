require File.expand_path('./config/initializers/civic_commons.rb')

Civiccommons::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # DO care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  ActionMailer::Base.smtp_settings = {
    :address              => Civiccommons::Config.smtp['address'],
    :domain               => Civiccommons::Config.smtp['domain'],
    :user_name            => Civiccommons::Config.smtp['username'],
    :password             => Civiccommons::Config.smtp['password'],
    :authentication       => "plain",
    :enable_starttls_auto => true
  }

  config.active_support.deprecation = :log

  # For devise gem
  config.action_mailer.default_url_options = { :host => Civiccommons::Config.devise['mailer_host'] }

end
