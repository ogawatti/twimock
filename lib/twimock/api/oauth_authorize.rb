require 'uri'
require 'addressable/uri'

module Twimock
  module API
    # ログインに成功したら
    # RequestTokenとUserの紐付けを行うAPI

    class OAuthAuthorize < OAuth
      METHOD         = "GET"
      PATH           = "/oauth/authorize"
      VIEW_DIRECTORY = File.expand_path("../../../../view", __FILE__)
      VIEW_FILE_NAME = "authorize.html"

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          begin
            raise if env["QUERY_STRING"].blank?
            query = query_string_to_hash(env["QUERY_STRING"])
            raise unless validate_query(query)
            raise unless request_token = Twimock::RequestToken.find_by_string(query.oauth_token)
            raise unless request_token.application_id
            user = Twimock::User.find_by_tiwtter_id_or_email(query["session[username_or_email]"])
            raise unless user = Twimock::User.find_by_tiwtter_id_or_email(query["session[username_or_email]"])

            request_token.user_id = user.id
            request_token.save!

            uri = Addressable::URI.new
            uri.query_values = { oauth_token: request_token.string,
                                 oauth_verifier: request_token.verifier }
            callback_url = Twimock::Config.callback_url + "?" + uri.query

            status = 302
            body = ""
            header = { "Content-Length" => body.bytesize,
                       "Location"       => callback_url }
            [ status, header, [ body ] ]
          rescue
            # ログインページにリダイレクト
            return unauthorized
          end
        else
          super
        end
      end

      def self.view
        File.read(filepath)
      end

      private

      def self.filepath
        File.join(VIEW_DIRECTORY, VIEW_FILE_NAME)
      end

      def query_string_to_hash(query_string)
        ary  = URI::decode_www_form(query_string)
        hash = Hash[ary]
        Hashie::Mash.new(hash)
      end

      def validate_query(query)
        false if query["session[username_or_email"].blank?
        false if query.remenber_me.to_i == 1
        false if query.oauth_token.blank?
        true
      end
    end
  end
end
