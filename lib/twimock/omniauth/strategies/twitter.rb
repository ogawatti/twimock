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
            case Twimock::Config.port
            when 443 then location.scheme = "https"
            when 80  then location.scheme = "http"
            else
              location.scheme = "http"
              location.port   = Twimock::Config.port
            end
            header["Location"] = location.to_s
          end

          [ status, header, body ]
        end
      end
    end
  end
end
