require 'twimock/api/application'
require 'twimock/api/oauth_access_token'
require 'twimock/api/oauth_request_token'
require 'twimock/api/oauth_authenticate'
require 'twimock/api/intent_sessions'
require 'twimock/api/oauth_authorize'
require 'twimock/api/account_verify_credentials'
require 'sham_rack'

module Twimock
  module API
    extend self

    HOSTNAME    = "api.twitter.com"
    PORT        = 443
    MIDDLEWARES = [ OAuthAccessToken, OAuthRequestToken, AccountVerifyCredentials ]

    def on
      ShamRack.at(HOSTNAME, PORT){|env| app.call(env) } unless on?
      true
    end
    
    def off
      ShamRack.unmount_all
      true
    end

    def on?
      !ShamRack.application_for(HOSTNAME, PORT).nil?
    end

    # Rack Application
    def app
      app = Twimock::API::Application.new
      MIDDLEWARES.inject(app) do |app, klass|
        app = klass.new(app)
      end
    end
  end
end
