require 'faker'
require 'twimock/database/table'
require 'twimock/access_token'
require 'twimock/request_token'

module Twimock
  # TODO: 要改善 AccessTokenをUserから分離
  class User < Database::Table
    TABLE_NAME = :users
    COLUMN_NAMES = [:id, :name, :twitter_id, :email, :password, :created_at]
    CHILDREN = [ Twimock::AccessToken, Twimock::RequestToken ]
    INFO_KEYS = [:id, :name, :created_at]

    def initialize(options={})
      opts = Hashie::Mash.new(options)
      id = opts.id || opts.identifier
      @id                  = (id.to_i > 0) ? id.to_i : (Faker::Number.number(10)).to_i
      @name                = opts.name                || create_user_name
      @twitter_id          = opts.twitter_id          || @name.downcase.gsub(" ", "_")
      @email               = opts.email               || Faker::Internet.email
      @password            = opts.password            || Faker::Internet.password
      @created_at     = opts.created_at
    end

    def info
      info_hash = Hashie::Mash.new({})
      INFO_KEYS.each { |key| info_hash[key] = self.instance_variable_get("@#{key}") }
      info_hash.id_str = info_hash.id.to_s
      info_hash
    end

    def generate_access_token(application_id=nil)
      if application_id
        application = Twimock::Application.find_by_id(application_id)
        raise Twimock::Errors::ApplicationNotFound unless application
      end

      access_token = Twimock::AccessToken.new({ application_id: application_id })
      if self.persisted?
        access_token.user_id = self.id
        access_token.save!
      end
      access_token
    end

    def self.find_by_tiwtter_id_or_email(value)
      user   = Twimock::User.find_by_twitter_id(value)
      user ||= Twimock::User.find_by_email(value)
    end

    private

    def create_user_name
      n = Faker::Name.name
      (n.include?("'") || n.include?(".")) ? create_user_name : n
    end
  end
end
