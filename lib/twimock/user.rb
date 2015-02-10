require 'faker'
require 'twimock/database/table'
require 'twimock/request_token'

module Twimock
  class User < Database::Table
    TABLE_NAME = :users
    COLUMN_NAMES = [:id, :name, :twitter_id, :password, :access_token, :access_token_secret, :application_id, :created_at]
    CHILDREN = [ RequestToken ]
    INFO_KEYS = [:id, :name, :created_at]

    def initialize(options={})
      opts = Hashie::Mash.new(options)
      id = opts.id || opts.identifier
      @id                  = (id.to_i > 0) ? id.to_i : (Faker::Number.number(10)).to_i
      @name                = opts.name                || create_user_name
      @twitter_id          = opts.twitter_id          || @name.downcase.gsub(" ", "_")
      @password            = opts.password            || Faker::Internet.password
      @access_token        = opts.access_token        || create_access_token
      @access_token_secret = opts.access_token_secret || Faker::Lorem.characters(45)
      app_id = opts.application_id.to_i
      @application_id = (app_id > 0) ? app_id : nil
      @created_at     = opts.created_at
    end

    def info
      info_hash = {}
      INFO_KEYS.each { |key| info_hash[key] = self.instance_variable_get("@#{key}") }
      info_hash[:id_str] = info_hash[:id].to_s
      Hashie::Mash.new(info_hash)
    end

    private

    def create_user_name
      n = Faker::Name.name
      (n.include?("'") || n.include?(".")) ? create_user_name : n
    end

    def create_access_token
      "#{@id}-#{Faker::Lorem.characters(39)}"
    end
  end
end
