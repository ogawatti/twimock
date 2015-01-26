require 'twimock/api/oauth'

module Twimock
  module API
    # OAuth 1.1 で利用するAPI
    # Request Token を取得する
    class OAuthRequestToken < OAuth
      METHOD = "POST"
      PATH   = "/oauth/request_token"

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          # 認証
          # Request Token発行
          [ "200 OK", header, [ body ] ]
        else
          super
        end
      end

      private

      def header
        { "Content-Length" => body.bytesize }
      end

      def body
        # とりあえず固定値
        params = { oauth_token: oauth_token,
                   oauth_token_secret: oauth_token_secret,
                   oauth_callback_confirmed: true }
        params.inject([]){|a, (k, v)| a << "#{k}=#{v}"}.join('&')
      end

      def oauth_token
        "rtbhw3pwBG1l498HYrDIRe8QSX09Bal1"
      end

      def oauth_token_secret
        "EqKuyJU3XcS7mgwLUbUYnBZYcLSDavJq"
      end
    end
  end
end
