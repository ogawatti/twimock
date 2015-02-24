require 'twimock/api/oauth'
require 'twimock/application'

module Twimock
  module API
    # Twitter OAuth で利用するAPI
    # Request Token を発行する
    class OAuth
      class RequestToken < OAuth
        METHOD = "POST"
        PATH   = "/oauth/request_token"
        AUTHORIZATION_REGEXP = /OAuth oauth_callback=\"(.*)\", oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_version=\"(.*)\".*/

        def call(env)
          return super unless called?(env)
          begin
            authorization_header = env["authorization"] || env["HTTP_AUTHORIZATION"]
            oauth = parse_authorization_header(authorization_header)
            consumer_key = oauth.consumer_key

            raise Twimock::Errors::InvalidConsumerKey.new if !validate_consumer_key(consumer_key)
            application = Twimock::Application.find_by_api_key(consumer_key)
          rescue Twimock::Errors::InvalidConsumerKey => @error
            return unauthorized
          rescue => @error
            return internal_server_error
          end

          request_token = create_request_token(application.id)
          status = "200 OK"
          params = { oauth_token:              request_token.string,
                     oauth_token_secret:       request_token.secret,
                     oauth_callback_confirmed: true }
          body   = params.inject([]){|a, (k, v)| a << "#{k}=#{v}"}.join('&')
          header = { "Content-Length" => body.bytesize.to_s }
          [ status, header, [ body ] ]
        end

        private

        def create_request_token(application_id)
          request_token = Twimock::RequestToken.new(application_id: application_id)
          request_token.save!
          request_token
        end
      end
    end
  end
end
