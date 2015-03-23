module Twimock
  module API
    # OAuthでブラウザ認証するAPI
    # GET http://api.twimock.com/authenticate?oauth_token=xxx
    class OAuth
      class Cancelled
        VIEW_DIRECTORY = File.expand_path("../../../../../view", __FILE__)
        VIEW_FILE_NAME = "oauth_cancelled.html.erb"

        def self.view(oauth_token)
          @oauth_token = oauth_token
          erb = ERB.new(File.read(filepath))
          erb.result(binding)
        end

        private

        def self.filepath
          File.join(VIEW_DIRECTORY, VIEW_FILE_NAME)
        end
      end
    end
  end
end
