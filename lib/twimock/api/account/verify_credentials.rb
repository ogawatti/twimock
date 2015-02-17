require 'twimock/api/oauth'
require 'twimock/user'

module Twimock
  module API
    # OAuth 1.1, OAuth Echo で利用するAPI
    # ユーザ情報を取得する
    module Account
      class VerifyCredentials < OAuth
        METHOD = "GET"
        PATH   = "/1.1/account/verify_credentials.json"
        AUTHORIZATION_REGEXP = /OAuth oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_version=\"(.*)\".*/

        def call(env)
          return super unless called?(env)

          begin
            oauth = parse_authorization_header(env["authorization"])
            access_token = oauth.token
            consumer_key = oauth.consumer_key

            raise Twimock::Errors::InvalidConsumerKey.new if !validate_consumer_key(consumer_key)
            application = Twimock::Application.find_by_api_key(consumer_key)
            raise Twimock::Errors::InvalidAccessToken.new if !validate_access_token(access_token, application.id)
            user = Twimock::User.find_by_access_token(access_token)
          rescue Twimock::Errors::InvalidAccessToken, Twimock::Errors::InvalidConsumerKey => @error
            return unauthorized
          rescue => @error
            return internal_server_error
          end

          status = '200 OK'
          body = user.info.to_json
          header = { "Content-Length" => body.bytesize }
          [ status, header, [ body ] ]
        end

        private

        def validate_access_token(access_token, application_id)
          return false if access_token.blank?
          return false unless user = Twimock::User.find_by_access_token(access_token)
          return false unless user.application_id
          return false unless user.application_id == application_id
          true
        end

        def validate_consumer_key(consumer_key)
          return false if consumer_key.blank?
          return false unless application = Twimock::Application.find_by_api_key(consumer_key)
          true
        end
      end
    end
  end
end
