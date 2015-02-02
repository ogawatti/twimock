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
#            raise unless validate_authorization_header(authorization)
#            raise unless @application = Twimock::Application.find_by_api_key(authorization.oauth_consumer_key)
#            raise unless @user = Twimock::User.find_by_access_token(authorization.oauth_token)
          rescue
            return unauthorized
          end
          status = '200 OK'
          header = { "Content-Length" => body.bytesize }
          [ status, header, [ body ] ]
        else
          super
        end
      end

      private

      def unauthorized
        [ "401 Unauthorized", {}, "" ]
      end

      def body
        # id, nameの値は固定
        "{
          \"id\":1422515903,
          \"id_str\":\"1422515903\",
          \"name\":\"test_account\",
          \"screen_name\":\"test_account\",
          \"location\":\"\",
          \"profile_location\":null,
          \"description\":\"\",
          \"url\":null,
          \"entities\":{\"description\":{\"urls\":[]}},
          \"protected\":false,
          \"followers_count\":1,
          \"friends_count\":1,
          \"listed_count\":1,
          \"created_at\":\"Wed Apr 27 00:00:00 +0000 2011\",
          \"favourites_count\":1,
          \"utc_offset\":32400,
          \"time_zone\":\"Tokyo\",
          \"geo_enabled\":true,
          \"verified\":false,
          \"statuses_count\":1,
          \"lang\":\"ja\",
          \"contributors_enabled\":false,
          \"is_translator\":false,
          \"is_translation_enabled\":false,
          \"profile_background_color\":\"022330\",
          \"profile_background_image_url\":\"http:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png\",
          \"profile_background_image_url_https\":\"https:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png\",
          \"profile_background_tile\":false,
          \"profile_image_url\":\"http:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_0_normal.png\",
          \"profile_image_url_https\":\"https:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_0_normal.png\",
          \"profile_banner_url\":\"\",
          \"profile_link_color\":\"0084B4\",
          \"profile_sidebar_border_color\":\"A8C7F7\",
          \"profile_sidebar_fill_color\":\"C0DFEC\",
          \"profile_text_color\":\"333333\",
          \"profile_use_background_image\":true,
          \"default_profile\":false,
          \"default_profile_image\":false,
          \"following\":false,
          \"follow_request_sent\":false,
          \"notifications\":false
        }".gsub!(/(^\s+|\n)/,'')
      end

=begin
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
=end

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
