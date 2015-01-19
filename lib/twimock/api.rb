require 'twimock/api/application'
require 'twimock/api/oauth_access_token'
require 'twimock/api/oauth_request_token'
require 'twimock/api/account_credentials'

module Twimock
  module API
    extend self

    HOSTNAME    = "api.twiter.com"
    PORT        = 443
    MIDDLEWARES = [ OAuthAccessToken, OAuthRequestToken, AccountCredentials ]

    def on
      ShamRack.at(HOST_NAME, PORT) do |env|
        app
      end
    end
    
    def off
      ShamRack.unmount_all
    end

    def on?
      !ShamRack.application_for(HOST_NAME, PORT).nil?
    end

    # Rack Application
    def app
      app = Twimock::API::Application.new
      MIDDLEWARES.inject(app) do |klass|
        app = klass.new(app)
      end
      app
    end
  end
end
