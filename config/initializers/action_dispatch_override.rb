if Rails.env.test?
  #taken from https://github.com/rails/rails/issues/546
  #monkey patch to fix the fact that ActionDispatch::Integration::Session blows
  #away the ApplicationController default_url_options which are necessary
  #for the specs to run
  module ActionDispatch
    module Integration
      class Session
        def default_url_options
          { :host => host, :protocol => https? ? "https" : "http" }.merge!(ApplicationController.new.default_url_options)
        end
      end
    end
  end
  
end