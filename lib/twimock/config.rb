require 'yaml'
require 'hashie'
require 'twimock/errors'
require 'twimock/database'

module Twimock
  module Config
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
        app_id     = data.app_id
        api_key    = data.api_key
        api_secret = data.api_secret
        users      = data.users

        # Validate data format
        [:app_id, :api_key, :api_secret, :users].each { |key| validate_format(key, data.send(key)) }
        users.each do |user|
          [:identifier, :access_token, :access_token_secret, :display_name, :password, :username].each do |key|
            validate_format(key, user.send(key))
          end
        end

        # Create application and user record
        app = Twimock::Application.create!({ id: app_id, api_key: api_key, api_secret: api_secret })
        users.each do |options|
          user = Twimock::User.new(options)
          unless Twimock::User.find_by_id(user.id)
            user.application_id = app.id
            user.save!
          end
        end
      end
    end

    private

    AVAILABLE_TYPE = { app_id: [String, Integer],
                       api_key: [String],
                       api_secret: [String],
                       users: [Array],
                       identifier: [String, Integer],
                       access_token: [String],
                       access_token_secret: [String],
                       display_name: [String],
                       password: [String],
                       username: [String] }

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
