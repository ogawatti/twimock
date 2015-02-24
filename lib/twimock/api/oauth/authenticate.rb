require 'uri'
require 'erb'

module Twimock
  module API
    # OAuthでブラウザ認証するAPI
    # GET http://api.twimock.com/authenticate?oauth_token=xxx
    class OAuth
      class Authenticate < OAuth
        METHOD = "GET"
        PATH   = "/oauth/authenticate"
        VIEW_DIRECTORY = File.expand_path("../../../../../view", __FILE__)
        VIEW_FILE_NAME = "authenticate.html.erb"

        def call(env)
          return super unless called?(env)
          begin
            request = Rack::Request.new(env)
            @oauth_token = request.params["oauth_token"]

            if !validate_request_token(@oauth_token)
              raise Twimock::Errors::InvalidRequestToken.new
            end

            status = 200
            body   = Twimock::API::OAuth::Authenticate.view(@oauth_token)
            header = { "Content-Length" => body.bytesize }
            [ status, header, [ body ] ]
          rescue Twimock::Errors::InvalidRequestToken => @error
            unauthorized
          rescue => @error
            internal_server_error
          end
        end

        def self.view(oauth_token)
          @action_url = Twimock::API::Intent::Sessions::PATH
          @oauth_token = oauth_token
          erb = ERB.new(File.read(filepath))
          erb.result(binding)
        end

        private

        def self.filepath
          File.join(VIEW_DIRECTORY, VIEW_FILE_NAME)
        end
      end
    end
  end
end
