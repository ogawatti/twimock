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
        raise Twimock::Errors::IncorrectDataFormat.new "app id is empty" unless validate_id(app_id)
        raise Twimock::Errors::IncorrectDataFormat.new "api key is empty" unless validate_key(api_key)
        raise Twimock::Errors::IncorrectDataFormat.new "api secret is empty" unless validate_secret(api_secret)
        raise Twimock::Errors::IncorrectDataFormat.new "users format is incorrect" unless validate_users(users)

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

    def validate_id(id)
      case id
      when String then !id.empty?
      when Integer then id >= 0
      else false
      end
    end

    def validate_key(api_key)
      case api_key
      when String then !api_key.empty?
      else false
      end
    end

    def validate_secret(api_secret)
      case api_secret
      when String then !api_secret.empty?
      else false
      end
    end

    def validate_users(users)
      case users
      when Array
        return false if users.empty?
        users.each {|user| return false unless validate_user(Hashie::Mash.new(user)) }
        true
      else false
      end
    end

    def validate_user(user)
      return false unless validate_id(user.identifier)
      [:access_token, :access_token_secret, :display_name, :password, :username].each do |key|
        value = user.send(key)
        case value
        when String then return false if value.empty?
        else return false
        end
      end
      true
    end
  end
end
