require 'twimock/database/table'
require 'twimock/net/http/responses'

module Twimock
  module Net
    module HTTP
      # Reference
      # /home/aries/.rvm/rubies/ruby-2.1.3/lib/ruby/2.1.0/net/http.rb:1126
      def get(path, initheader = {}, dest = nil, &block)
        res = HTTPOK.new
      end  
    end
  end
end
