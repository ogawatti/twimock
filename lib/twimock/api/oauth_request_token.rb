require 'twimock/api/oauth'
require 'twimock/application'

module Twimock
  module API
    # OAuth 1.1 で利用するAPI
    # Request Token を取得する
    class OAuthRequestToken < OAuth
      METHOD = "POST"
      PATH   = "/oauth/request_token"
      AUTHORIZATION_REGEXP = /OAuth oauth_callback=\"(.*)\", oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_version=\"(.*)\".*/

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          return failure unless validate_authorization_header(env)

          request_token = create_request_token
          status = "200 OK"
          params = { oauth_token:              request_token.string,
                     oauth_token_secret:       request_token.secret,
                     oauth_callback_confirmed: true }
          body   = params.inject([]){|a, (k, v)| a << "#{k}=#{v}"}.join('&')
          header = { "Content-Length" => body.bytesize }

          [ status, header, [ body ] ]
        else
          super
        end
      end

      private

      def failure
        [ "401 Unauthorized", {}, "" ]
      end

      def validate_authorization_header(env)
        begin
          auth_header = env["authorization"]
          return false if auth_header.blank?

          @authorization = parse_authorization_header(auth_header.first)
          return false unless @authorization.oauth_callback.size > 0
          return false unless @authorization.oauth_consumer_key.size > 0
          return false unless @authorization.oauth_nonce.size > 0
          return false unless @authorization.oauth_signature.size > 0
          return false unless @authorization.oauth_signature_method == "HMAC-SHA1"
          return false unless validate_consumer_key
          return false unless @authorization.oauth_timestamp.to_i > 0
          return false unless @authorization.oauth_version == "1.0"
        rescue => e
          return false
        end
        true
      end

      def parse_authorization_header(auth_header)
        raise unless auth_header =~ AUTHORIZATION_REGEXP
        authorization = Hashie::Mash.new
        authorization.oauth_callback         = $1
        authorization.oauth_consumer_key     = $2
        authorization.oauth_nonce            = $3
        authorization.oauth_signature        = $4
        authorization.oauth_signature_method = $5
        authorization.oauth_timestamp        = $6
        authorization.oauth_version          = $7
        authorization
      end

      def validate_consumer_key
        return false unless api_key = @authorization.oauth_consumer_key
        @application = Twimock::Application.find_by_api_key(api_key)
        return false unless @application
        true
      end

      def create_request_token
        request_token = Twimock::RequestToken.new(application_id: @application.id)
        request_token.save!
        request_token
      end
    end
  end
end
