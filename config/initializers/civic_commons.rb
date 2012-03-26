if !defined?(Civiccommons::Config)

  require 'config/configurator'
  module Civiccommons

    class Config
      include Configurator

      load_config(:file => File.join(Rails.root, "config", "civic_commons.yml"), :environment => Rails.env)
      require_config :config => {:email => :default_email}, :description => "default email config"
      require_config :config => {:mailer => :intercept}, :description => "mailer intercept config"
      default_config :of => {:mailer => :intercept_email}, :to => {:email => :default_email}
      default_config :of => {:mailer => :mailchimp}, :to => false
      

    end
  end

end

