require 'twimock/api/oauth'
require 'twimock/user'

module Twimock
  module API
    # OAuth 1.1, OAuth Echo で利用するAPI
    # ユーザ情報を取得する
    class AccountVerifyCredentials < OAuth
      METHOD = "GET"
      PATH   = "/1.1/account/verify_credentials.json"

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          # 認証
          # ユーザ情報発行
          [ "200 OK", {}, [] ]
        else
          super
        end
      end
    end
  end
end
