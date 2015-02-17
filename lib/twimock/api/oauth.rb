require 'twimock/api/oauth/access_token'
require 'twimock/api/oauth/request_token'
require 'twimock/api/oauth/authenticate'
require 'twimock/api/intent/sessions'
require 'twimock/api/account/verify_credentials'
require 'twimock/errors'

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

      def called?(env)
        request = Rack::Request.new(env)
        request.request_method == self.class::METHOD && request.path == self.class::PATH
      end

      def unauthorized
        generate_error_response(401)
      end

      def internal_server_error
        generate_error_response(500)
      end

      def parse_authorization_header(authorization_header)
        authorization = case authorization_header
        when Array  then authorization_header.first
        when String then authorization_header
        else ""
        end

        oauth = Hashie::Mash.new
        authorization.scan(/oauth_(\w+)=\"([\w%-.]+)\"/) do |key, value|
          oauth[key] = value
        end
        oauth
      end

      def generate_error_response(status)
        error_code = @error.class.to_s.split("::").last
        body   = { error: { code: error_code } }.to_json
        header = { "Content-Type"   => "application/json; charset=utf-8",
                   "Content-Length" => body.bytesize }
        [ status, header, [ body ] ]
      end
    end
  end
end
