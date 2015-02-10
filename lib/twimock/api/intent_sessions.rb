require 'uri'
require 'erb'
require 'json'
require 'twimock/errors'

module Twimock
  module API
    # POST https://twitter.com/intent/sessions
    #   body: { username_or_email: "xxx", password: "xxx", oauth_token: "xxx" }
    class IntentSessions < OAuth
      METHOD = "POST"
      PATH   = "/intent/sessions"

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          begin
            request = Rack::Request.new(env)
            body = query_string_to_hash(request.body.read)
            @oauth_token       = body.oauth_token
            @username_or_email = body.username_or_email
            @password          = body.password

            if !validate_oauth_token(@oauth_token)
              raise Twimock::Errors::InvalidRequestToken.new
            elsif !(user = Twimock::User.find_by_tiwtter_id_or_email(@username_or_email))
              raise Twimock::Errors::InvalidUsernameOrEmail.new 
            elsif @password.blank? || @password != user.password
              raise Twimock::Errors::InvalidPassword.new 
            end

            uri = Addressable::URI.new
            uri.path = Twimock::API::OAuthAuthorize::PATH
            uri.query_values = { oauth_token: @oauth_token,
                                 remember_me: 1,
                                 "session[username_or_email]" => @username_or_email }

            status = 302
            body   = ""
            header = { "Content-Length" => body.bytesize,
                       "Location" => uri.to_s }
            [ status, header, [ body ] ]
          rescue Twimock::Errors::InvalidUsernameOrEmail, Twimock::Errors::InvalidPassword => @error
            response = unauthorized
            response[0] = 302
            response[1].merge!( {"Location" => "/oauth/authenticate?oauth_token=#{@oauth_token}" })
            response
          rescue Twimock::Errors::InvalidRequestToken => @error
            unauthorized
          rescue
            return [ 500, {}, [""] ]
          end
        else
          super
        end
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

      def query_string_to_hash(query_string)
        ary  = URI::decode_www_form(query_string)
        hash = Hash[ary]
        Hashie::Mash.new(hash)
      end

      def validate_oauth_token(oauth_token)
        return false if oauth_token.blank?
        return false unless request_token = Twimock::RequestToken.find_by_string(oauth_token)
        return false unless request_token.application_id
        true
      end
    end
  end
end
