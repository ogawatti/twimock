require "active_support/time"
require "twimock/version"
require "twimock/database"
require "twimock/config"
require "twimock/application"
require "twimock/user"
require "twimock/auth_hash"
require "twimock/errors"

module Twimock
  extend self

  def auth_hash(access_token=nil)
    if access_token.kind_of?(String) && access_token.size > 0
      user = Twimock::User.find_by_access_token(access_token)
      if user
        Twimock::AuthHash.new({
          provider:    "twitter",
          uid:         user.id,
          info:        { name: user.name },
          credentials: { token: access_token, expires_at: Time.now + 60.days },
          extra:       { raw_info: { id: user.id, name: user.name } }
        })
      else
        Twimock::AuthHash.new
      end 
    else
      Twimock::AuthHash.new
    end 
  end
end
