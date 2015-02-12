require 'twimock/api/application'
require 'twimock/api/oauth'
require 'sham_rack'

module Twimock
  module API
    extend self

    HOSTNAME    = "api.twitter.com"
    PORT        = 443
    MIDDLEWARES = [ OAuth::AccessToken, OAuth::RequestToken, Account::VerifyCredentials ]

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
