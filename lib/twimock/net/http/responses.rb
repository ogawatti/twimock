module Twimock
  module Net
    class HTTPResponse
      attr_accessor :http_version, :code, :message, :body

      def initialize(httpv, code, msg)
        @http_version = httpv
        @code         = code
        @message      = msg
        @body = nil
      end 
    end

    class HTTPSuccess < HTTPResponse
    end

    class HTTPOK < HTTPSuccess
      def initialize
        super(nil, "200", "OK")
      end
    end
  end
end
