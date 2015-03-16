require "active_support/time"
require "twimock/version"
require "twimock/database"
require "twimock/config"
require "twimock/application"
require "twimock/user"
require "twimock/access_token"
require "twimock/request_token"
require "twimock/auth_hash"
require "twimock/errors"
require "twimock/api"
require "twimock/omniauth_twitter"

module Twimock
  extend self

  def auth_hash(access_token_string=nil)
    return Twimock::AuthHash.new unless validate_access_token_string(access_token_string)

    if access_token = Twimock::AccessToken.find_by_string(access_token_string)
      if user = Twimock::User.find_by_id(access_token.user_id)
        hash = Twimock::AuthHash.new({
          provider:    "twitter",
          uid:         user.id,
          info:        { name: user.name },
          credentials: { token: access_token.string, expires_at: Time.now + 60.days },
          extra:       { raw_info: { id: user.id, name: user.name } }
        })
      end
    end
    hash || Twimock::AuthHash.new
  end

  private

  def validate_access_token_string(string)
    string.kind_of?(String) && string.size > 0
  end
end
