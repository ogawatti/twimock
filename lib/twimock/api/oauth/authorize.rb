require 'uri'
require 'erb'

module Twimock
  module API
    # 認証キャンセル後の画面を返すAPI
    # GET http://api.twimock.com/oauth/authorize
    class OAuth
      class Authorize < OAuth
        METHOD = "GET"
        PATH   = "/oauth/authorize"
        VIEW_DIRECTORY = File.expand_path("../../../../../view", __FILE__)
	VIEW_FILE_NAME = "authenticate_cancel.html.erb"

        def call(env)
          return super unless called?(env)
          status = 302
          body   = Twimock::API::OAuth::Authorize.view
          header = { "Content-Length" => body.bytesize.to_s }
          [ status, header, [ body ] ]
        end

        def self.view
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
