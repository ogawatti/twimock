require 'faker'
require 'twimock/database/table'
require 'twimock/user'

module Twimock
  class Application < Database::Table
    TABLE_NAME = :applications
    COLUMN_NAMES = [:id, :api_key, :api_secret, :created_at]
    CHILDREN = [ User ]

    # WANT : DBに登録済みの値と重複しないようにする(id, api_secret)
    def initialize(options={})
      opts = Hashie::Mash.new(options)
      @id         = ( opts.id.to_i > 0 ) ? opts.id.to_i : Faker::Number.number(10).to_i
      @api_key        = opts.api_key    || Faker::Lorem.characters(25)
      @api_secret     = opts.api_secret || Faker::Lorem.characters(50)
      @created_at = opts.created_at
    end
  end
end
