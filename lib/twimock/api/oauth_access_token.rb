require 'twimock/api/oauth'
require 'twimock/user'

module Twimock
  module API
    # OAuth 1.1 で利用するAPI
    # Access Token を取得する
    class OAuthAccessToken < OAuth
      METHOD = "POST"
      PATH   = "/oauth/access_token"
      AUTHORIZATION_REGEXP = /OAuth oauth_body_hash=\"(.*)\", oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_verifier=\"(.*)\", oauth_version=\"(.*)\"/

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          begin
            auth_header = env["authorization"]
            raise if auth_header.blank?
            authorization = parse_authorization_header(auth_header.first)
            raise unless validate_authorization_header(authorization)
            raise unless application   = Twimock::Application.find_by_api_key(authorization.oauth_consumer_key)
            raise unless request_token = Twimock::RequestToken.find_by_string(authorization.oauth_token)
            raise unless request_token.application_id == application.id
            raise unless user          = Twimock::User.find_by_id(request_token.user_id)
          rescue
            return unauthorized
          end

          status = "200 OK"
          params = {
            oauth_token:        user.access_token,
            oauth_token_secret: user.access_token_secret,
            user_id:            user.id,
            screen_name:        user.twitter_id
          }
          body   = params.inject([]){|a, (k, v)| a << "#{k}=#{v}"}.join('&')
          header = { "Content-Length" => body.bytesize }

          [ status, header, [ body ] ]
        else
          super
        end
      end

      private

      def parse_authorization_header(auth_header)
        raise unless auth_header =~ AUTHORIZATION_REGEXP
        authorization = Hashie::Mash.new
        authorization.oauth_body_hash        = $1
        authorization.oauth_consumer_key     = $2
        authorization.oauth_nonce            = $3
        authorization.oauth_signature        = $4
        authorization.oauth_signature_method = $5
        authorization.oauth_timestamp        = $6
        authorization.oauth_token            = $7
        authorization.oauth_verifier         = $8
        authorization.oauth_version          = $9
        authorization
      end

      def validate_authorization_header(authorization)
        return false unless authorization.oauth_body_hash.size > 0
        return false unless authorization.oauth_consumer_key.size > 0
        return false unless authorization.oauth_nonce.size > 0
        return false unless authorization.oauth_signature.size > 0
        return false unless authorization.oauth_signature_method == "HMAC-SHA1"
        return false unless authorization.oauth_timestamp.to_i > 0
        return false unless authorization.oauth_token.size > 0
        return false unless authorization.oauth_verifier.size > 0
        return false unless authorization.oauth_version == "1.0"
        true
      end
    end
  end
end
