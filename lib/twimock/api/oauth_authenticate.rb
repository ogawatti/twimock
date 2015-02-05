require 'uri'

module Twimock
  module API
    # OAuthでブラウザ認証するAPI
    class OAuthAuthenticate < OAuth
      METHOD = "GET"
      PATH   = "/oauth/authenticate"
      VIEW_DIRECTORY = File.expand_path("../../../../view", __FILE__)
      VIEW_FILE_NAME = "authenticate.html"

      def call(env)
        if env["REQUEST_METHOD"] == METHOD && env["PATH_INFO"] == PATH
          begin
            raise if env["QUERY_STRING"].blank?
            query = query_string_to_hash(env["QUERY_STRING"])
            raise unless validate_query(query)
            raise unless request_token = Twimock::RequestToken.find_by_string(query.oauth_token)
            raise unless request_token.application_id

            # TODO : HTMLにoauth_token埋め込み
            status = 200
            body   = OAuthAuthenticate.view
            header = { "Content-Length" => body.bytesize }
            [ status, header, [ body ] ]
          rescue
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
        false unless query.oauth_token.blank?
        true
      end
    end
  end
end
