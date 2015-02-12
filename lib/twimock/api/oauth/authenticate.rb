require 'uri'
require 'erb'
require 'twimock/errors'

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
          if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
            begin
              request = Rack::Request.new(env)
              @oauth_token = request.params["oauth_token"]

              if !validate_oauth_token(@oauth_token)
                raise Twimock::Errors::InvalidRequestToken.new
              end

              status = 200
              body   = Twimock::API::OAuth::Authenticate.view(@oauth_token)
              header = { "Content-Length" => body.bytesize }
              [ status, header, [ body ] ]
            rescue Twimock::Errors::InvalidRequestToken => @error
              unauthorized
            rescue => e
              return [ 500, {}, [""] ]
            end
          else
            super
          end
        end

        def self.view(oauth_token)
          @action_url = Twimock::API::Intent::Sessions::PATH
          @oauth_token = oauth_token
          erb = ERB.new(File.read(filepath))
          erb.result(binding)
        end

        private

        def unauthorized
          status = 401
          error_code = @error.class.to_s.split("::").last
          body   = { error: { code: error_code } }.to_json
          header = { "Content-Type"   => "application/json; charset=utf-8",
                     "Content-Length" => body.bytesize }
          return [ status, header, [ body ] ]
        end

        def validate_oauth_token(oauth_token)
          return false if oauth_token.blank?
          return false unless request_token = Twimock::RequestToken.find_by_string(oauth_token)
          return false unless request_token.application_id
          true
        end

        def self.filepath
          File.join(VIEW_DIRECTORY, VIEW_FILE_NAME)
        end
      end
    end
  end
end
