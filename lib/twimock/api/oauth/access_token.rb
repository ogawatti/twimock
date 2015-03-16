require 'twimock/api/oauth'
require 'twimock/user'

module Twimock
  module API
    class OAuth
    # OAuth 1.1 で利用するAPI
    # Access Token を取得する
      class AccessToken < OAuth
        METHOD = "POST"
        PATH   = "/oauth/access_token"
        AUTHORIZATION_REGEXP = /OAuth oauth_body_hash=\"(.*)\", oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_verifier=\"(.*)\", oauth_version=\"(.*)\"/

        def call(env)
          return super unless called?(env)
          begin
            authorization_header = env["authorization"] || env["HTTP_AUTHORIZATION"]
            oauth = parse_authorization_header(authorization_header)
            consumer_key  = oauth.consumer_key
            request_token = oauth.token

            raise Twimock::Errors::InvalidConsumerKey.new if !validate_consumer_key(consumer_key)
            application = Twimock::Application.find_by_api_key(consumer_key)
            if !validate_request_token(request_token, application.id)
              raise Twimock::Errors::InvalidRequestToken.new 
            end
            request_token = Twimock::RequestToken.find_by_string(request_token)
            user = Twimock::User.find_by_id(request_token.user_id)
          rescue Twimock::Errors::InvalidConsumerKey, Twimock::Errors::InvalidRequestToken => @error
            return unauthorized
          rescue => @error
            return internal_server_error
          end

          status = "200 OK"
          params = {
            oauth_token:        user.access_token,
            oauth_token_secret: user.access_token_secret,
            user_id:            user.id,
            screen_name:        user.twitter_id
          }
          body   = params.inject([]){|a, (k, v)| a << "#{k}=#{v}"}.join('&')
          header = { "Content-Length" => body.bytesize.to_s }

          [ status, header, [ body ] ]
        end

        private

        def validate_request_token(request_token, application_id)
          return false unless super(request_token)

          request_token = Twimock::RequestToken.find_by_string(request_token)
          return false unless request_token.application_id == application_id
          return false unless User.find_by_id(request_token.user_id)
          true
        end
      end
    end
  end
end
