require 'uri'
require 'erb'
require 'json'
require 'addressable/uri'
require 'twimock/errors'

module Twimock
  module API
    # POST https://twitter.com/intent/sessions
    #   body: { 'session[username_or_email]' => "xxx", 'session[password]' => "xxx", oauth_token: "xxx" }
    module Intent
      class Sessions < OAuth
        METHOD = "POST"
        PATH   = "/intent/sessions"

        def call(env)
          return super unless called?(env)
          begin
            # TODO : アプリ認可をキャンセルした場合に対応する
            request = Rack::Request.new(env)
            body = query_string_to_hash(request.body.read)
            @oauth_token       = body.oauth_token
            @username_or_email = body["session[username_or_email]"]
            @password          = body["session[password]"]

            if body.cancel
              raise Twimock::Errors::AuthenticationCancel.new
            elsif !validate_request_token(@oauth_token)
              raise Twimock::Errors::InvalidRequestToken.new
            elsif !(user = Twimock::User.find_by_tiwtter_id_or_email(@username_or_email))
              raise Twimock::Errors::InvalidUsernameOrEmail.new 
            elsif @password.blank? || @password != user.password
              raise Twimock::Errors::InvalidPassword.new 
            end
            request_token = Twimock::RequestToken.find_by_string(@oauth_token)
            request_token.user_id = user.id
            request_token.save!

            uri = Addressable::URI.new
            uri.query_values = { oauth_token: request_token.string,
                                 oauth_verifier: request_token.verifier }
            callback_url = Twimock::Config.callback_url + "?" + uri.query

            status = 302
            body   = ""
            header = { "Content-Length" => body.bytesize.to_s,
                       "Location" => callback_url }
            [ status, header, [ body ] ]
          rescue Twimock::Errors::AuthenticationCancel
            filepath = File.join(Twimock::API::OAuth::Authenticate::VIEW_DIRECTORY, "authenticate_cancel.html.erb")
            status = 200
            body   = ERB.new(File.read(filepath)).result(binding)
            header = { "Content-Length" => body.bytesize.to_s }
            [ status, header, [ body ] ]
          rescue Twimock::Errors::InvalidUsernameOrEmail, Twimock::Errors::InvalidPassword => @error
            response = unauthorized
            response[0] = 302
            response[1].merge!( {"Location" => "/oauth/authenticate?oauth_token=#{@oauth_token}" })
            response
          rescue Twimock::Errors::InvalidRequestToken => @error
            return unauthorized
          rescue => @error
            internal_server_error
          end
        end
      end
    end
  end
end
