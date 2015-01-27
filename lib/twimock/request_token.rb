require 'faker'
require 'twimock/database/table'

module Twimock
  class RequestToken < Database::Table
    TABLE_NAME = :request_tokens
    COLUMN_NAMES = [:id, :string, :secret, :user_id, :created_at]

    def initialize(options={})
      opts = Hashie::Mash.new(options)
      id = opts.id.to_i
      @id             = id if id > 0
      @string         = opts.string || Faker::Lorem.characters(32)
      @secret         = opts.secret || Faker::Lorem.characters(32)
      user_id = opts.user_id.to_i
      @user_id        = user_id if user_id > 0
      @created_at     = opts.created_at
    end
  end
end
