require 'twimock/api/oauth/access_token'
require 'twimock/api/oauth/request_token'
require 'twimock/api/oauth/authenticate'
require 'twimock/api/oauth/authorize'
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

      def validate_consumer_key(consumer_key)
        return false if consumer_key.blank?
        return false unless application = Twimock::Application.find_by_api_key(consumer_key)
        true
      end

      def validate_request_token(request_token)
        return false if request_token.blank?
        return false unless request_token = Twimock::RequestToken.find_by_string(request_token)
        return false unless request_token.application_id
        true
      end

      def validate_access_token(access_token_string, application_id)
        return false if access_token_string.blank?
        return false unless access_token = Twimock::AccessToken.find_by_string(access_token_string)
        return false unless access_token.application_id
        return false unless access_token.application_id == application_id
        true
      end

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

      def query_string_to_hash(query_string)
        ary = URI.decode(query_string).split("&").inject([]){|a, s| a << s.split("=")}
        Hashie::Mash.new(Hash[ary])
      end

      def generate_error_response(status)
        error_code = @error.class.to_s.split("::").last
        body   = { error: { code: error_code } }.to_json
        header = { "Content-Type"   => "application/json; charset=utf-8",
                   "Content-Length" => body.bytesize.to_s }
        [ status, header, [ body ] ]
      end
    end
  end
end
