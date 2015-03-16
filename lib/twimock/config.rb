require 'yaml'
require 'hashie'
require 'twimock/errors'
require 'twimock/database'
require 'active_support'

module Twimock
  module Config
    mattr_accessor :host
    mattr_accessor :port
    mattr_accessor :callback_url

    @@host         = "api.twimock.com"
    @@port         = 443
    @@callback_url = "http://localhost/auth/twiter/callback"

    extend self

    def default_database
      Twimock::Database.new
    end

    def database
      default_database
    end

    def reset_database
      db = Twimock::Database.new
      db.disconnect!
      db.drop
    end

    def load_users(ymlfile)
      load_data = YAML.load_file(ymlfile)
      raise Twimock::Errors::IncorrectDataFormat.new "data is not Array" unless load_data.kind_of?(Array)

      load_data.each do |app_data|
        data = Hashie::Mash.new(app_data)
        app_id     = data.id
        api_key    = data.api_key
        api_secret = data.api_secret
        users      = data.users

        # Validate data format
        [:id, :api_key, :api_secret, :users].each {|key| validate_format(key, data.send(key)) }
        users.each do |user|
          [:id, :name, :password].each {|key| validate_format(key, user.send(key)) }
        end

        # Create application and user record
        app = Twimock::Application.create!({ id: app_id, api_key: api_key, api_secret: api_secret })
        users.each do |options|
          access_token = AccessToken.new
          access_token.string = options.delete(:access_token)
          access_token.secret = options.delete(:access_token_secret)
          user = Twimock::User.new(options)
          user.save! unless Twimock::User.find_by_id(user.id)
          unless Twimock::AccessToken.find_by_string(access_token.string)
            access_token.user_id = user.id
            access_token.save!
          end
        end
      end
    end

    private

    AVAILABLE_TYPE = { id: [String, Integer],
                       api_key: [String],
                       api_secret: [String],
                       users: [Array],
                       name: [String],
                       password: [String] }

    def available?(key, value)
      return false unless AVAILABLE_TYPE[key].any? { |t| value.kind_of?(t) }
      case value
      when String, Array
         value.present?
      when Integer
         value >= 0
      end
    end

    def validate_format(key, value)
      raise Twimock::Errors::IncorrectDataFormat.new "format of #{key} is incorrect" unless available?(key, value)
    end
  end
end
