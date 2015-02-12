require 'twimock/api/oauth/access_token'
require 'twimock/api/oauth/request_token'
require 'twimock/api/oauth/authenticate'
require 'twimock/api/intent/sessions'
require 'twimock/api/account/verify_credentials'

module Twimock
  module API
    class OAuth
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      end

      private

      def unauthorized
        [ "401 Unauthorized", {}, [ "" ] ]
      end
    end
  end
end
