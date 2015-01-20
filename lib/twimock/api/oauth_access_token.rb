require 'twimock/api/oauth'
require 'twimock/user'

module Twimock
  module API
    # OAuth 1.1 で利用するAPI
    # Access Token を取得する
    class OAuthAccessToken < OAuth
      METHOD = "POST"
      PATH   = "/oauth/access_token"

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          # 認証
          # Access Token発行
          [ "201 Created", {}, [] ]
        else
          super
        end
      end
    end
  end
end
