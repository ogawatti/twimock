require 'net/http'
require "active_support/time"
require "twimock/version"
require "twimock/database"
require "twimock/config"
require "twimock/application"
require "twimock/user"
require "twimock/auth_hash"
require "twimock/net/http"
require "twimock/errors"

module Twimock
  extend self
  @@enable = false

  def on?
    @@enable
  end

  def on
    unless Twimock.on?
      ::Net::HTTP.class_eval do
        alias_method :__get, :get; remove_method :get
        include ::Twimock::Net::HTTP
      end 
      @@enable = true
    end
    true
  end

  def off
    if Twimock.on?
      ::Net::HTTP.class_eval do
        alias_method :get, :__get; remove_method :__get
      end
      @@enable = false
    end
    true
  end

=begin
  def on
    ::Hoge.class_eval do
      alias_method :__hoge, :hoge; remove_method :hoge
      class << ::Hoge; self; end.class_eval do
        alias_method :__foo, :foo; remove_method :foo
      end
      include ::Mock::Hoge
    end
  end

  def off
    ::Hoge.class_eval do
      alias_method :hoge, :__hoge; remove_method :__hoge
      class << ::Hoge; self; end.class_eval do
        alias_method :foo,  :__foo;  remove_method :__foo
      end
    end
  end

  module Hoge
    def hoge; p "hogeeeee"; end

    module ClassMethods
      def foo; p "fooooooo"; end
    end

    extend ClassMethods
    
    def self.included(klass)
      klass.extend ClassMethods
    end
  end
=end

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
