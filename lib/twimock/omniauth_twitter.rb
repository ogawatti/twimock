require 'twimock/omniauth/strategies/twitter'
require 'omniauth-twitter'

module Twimock
  module OmniAuthTwitter
    extend self
    @@enable = false

    def on?
      @@enable
    end

    def on
      unless Twimock::OmniAuthTwitter.on?
        ::OmniAuth::Strategies::Twitter.class_eval do
          alias_method  :__request_phase, :request_phase
          remove_method :request_phase
          include Twimock::OmniAuth::Strategies::Twitter
        end
        @@enable = true
      end
      true
    end

    def off
      if Twimock::OmniAuthTwitter.on?
        ::OmniAuth::Strategies::Twitter.class_eval do
          alias_method  :request_phase, :__request_phase
          remove_method :__request_phase
        end
        @@enable = false
      end
      true
    end
  end
end
