require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

module Civiccommons
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    config.autoload_paths += %W(#{config.root}/app/concerns/**/*.rb)
    config.autoload_paths += %W(#{config.root}/app/observers/**/*.rb)
    config.autoload_paths += %W(#{config.root}/app/presenters/**/*.rb)
    config.autoload_paths += %W(#{config.root}/app/services/**/*.rb)
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += %W(#{config.root}/lib/ccml/**/*.rb)
    config.autoload_paths += %W(#{config.root}/lib/utilities/**/*.rb)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers = :activity_observer, :person_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure generators values. Many other options are available, be sure to check the documentation.
    config.generators do |g|
      g.test_framework      :rspec, :fixture => true
      g.integration_tool    :rspec
      g.fixture_replacement :factory_girl
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # For devise gem
    config.action_mailer.default_url_options = { :host => Rails.env == "production" ? "" : "localhost:3000" }

    # Add <style> tags to the bad_tags collection so that internal styles are not shown
    config.action_view.sanitized_allowed_attributes = ['style']
    config.action_view.sanitized_bad_tags = ['style']
  end
end
