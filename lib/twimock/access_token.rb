require 'faker'
require 'twimock/database/table'

module Twimock
  class AccessToken < Database::Table
    TABLE_NAME = :access_tokens
    COLUMN_NAMES = [:id, :string, :secret, :application_id, :user_id, :created_at]

    def initialize(options={})
      opts = Hashie::Mash.new(options)
      id = opts.id.to_i
      @id             = id if id > 0
      app_id = opts.application_id.to_i
      @application_id = app_id if app_id > 0
      user_id = opts.user_id.to_i
      @user_id        = user_id if user_id > 0

      @string = generate_string(opts.string)
      @secret = opts.secret || Faker::Lorem.characters(45)
      @created_at     = opts.created_at
    end

    private

    def generate_string(string=nil)
      return string if string
      return "#{@user_id}-#{Faker::Lorem.characters(39)}" if @user_id
      return Faker::Lorem.characters(50)
    end
  end
end
