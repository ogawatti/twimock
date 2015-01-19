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
        else
          super
        end
      end
    end
  end
end
