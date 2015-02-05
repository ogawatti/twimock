require 'uri'

module Twimock
  module OmniAuth
    module Strategies
      module Twitter
        def request_phase
          status, header, body = __request_phase
          location = URI.parse(header["Location"])

          if status == 302 && location.host == "api.twitter.com"
            location.host   = Twimock::Config.host
            location.port   = Twimock::Config.port
            location.scheme = (location.port == 443) ? "https" : "http"
            header["Location"] = location.to_s
          end

          [ status, header, body ]
        end
      end
    end
  end
end
