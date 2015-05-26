require 'uri'
require 'erb'

module Twimock
  module API
    # 認証キャンセル後の画面を返すAPI
    # POST http://api.twimock.com/oauth/authorize
    class OAuth
      class Authorize < OAuth
        METHOD = "GET"
        PATH   = "/oauth/authorize"

        def call(env)
          return super unless called?(env)
          begin
            request = Rack::Request.new(env)
            @oauth_token = request.params["oauth_token"]
            @cancel      = request.params["cancel"]

            if !validate_request_token(@oauth_token)
              raise Twimock::Errors::InvalidRequestToken.new
            elsif @cancel == "true"
              raise Twimock::Errors::OAuthCancelled.new
            end
          rescue Twimock::Errors::InvalidRequestToken => @error
            unauthorized
          rescue Twimock::Errors::OAuthCancelled => @error
            oauth_cancelled
          rescue => @error
            internal_server_error
          end

          status = 200
          body = ""
          header = { "Content-Length" => body.bytesize.to_s }
          [ status, header, [ body ] ]
        end

        private

        def oauth_cancelled
          status = 200
          body   = Twimock::API::OAuth::Cancelled.view(@oauth_token)
          header = { "Content-Length" => body.bytesize.to_s }
          [ status, header, [ body ] ]
        end
      end
    end
  end
end
