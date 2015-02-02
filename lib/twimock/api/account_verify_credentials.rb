require 'twimock/api/oauth'
require 'twimock/user'

module Twimock
  module API
    # OAuth 1.1, OAuth Echo で利用するAPI
    # ユーザ情報を取得する
    class AccountVerifyCredentials < OAuth
      METHOD = "GET"
      PATH   = "/1.1/account/verify_credentials.json"
      AUTHORIZATION_REGEXP = /OAuth oauth_consumer_key=\"(.*)\", oauth_nonce=\"(.*)\", oauth_signature=\"(.*)\", oauth_signature_method=\"(.*)\", oauth_timestamp=\"(.*)\", oauth_token=\"(.*)\", oauth_version=\"(.*)\".*/

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          # 認証
          # ユーザ情報発行
          begin
            auth_header = env["authorization"]
            raise if auth_header.blank?
            authorization = parse_authorization_header(auth_header.first)
            raise unless validate_authorization_header(authorization)
            raise unless application = Twimock::Application.find_by_api_key(authorization.oauth_consumer_key)
            raise unless user = Twimock::User.find_by_application_id(application.id)
            raise unless user.access_token == authorization.oauth_token
            # TODO: 要改善 AccessTokenをUserから分離
          rescue
            return unauthorized
          end
          status = '200 OK'
          body = { id: user.id,
                   id_str: user.id.to_s,
                   name: user.name,
                   created_at: user.created_at }.to_json
          header = { "Content-Length" => body.bytesize }
          [ status, header, [ body ] ]
        else
          super
        end
      end

      private

      def validate_authorization_header(authorization)
        return false unless authorization.oauth_consumer_key.size > 0
        return false unless authorization.oauth_nonce.size > 0
        return false unless authorization.oauth_signature.size > 0
        return false unless authorization.oauth_signature_method == "HMAC-SHA1"
        return false unless authorization.oauth_timestamp.to_i > 0
        return false unless authorization.oauth_token.size > 0
        return false unless authorization.oauth_version == "1.0"
        true
      end

      def parse_authorization_header(auth_header)
        raise unless auth_header =~ AUTHORIZATION_REGEXP
        authorization = Hashie::Mash.new
        authorization.oauth_consumer_key     = $1
        authorization.oauth_nonce            = $2
        authorization.oauth_signature        = $3
        authorization.oauth_signature_method = $4
        authorization.oauth_timestamp        = $5
        authorization.oauth_token            = $6
        authorization.oauth_version          = $7
        authorization
      end
    end
  end
end
