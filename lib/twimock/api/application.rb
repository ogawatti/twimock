module Twimock
  module API
    # Rack Application
    # Net::HTTP は ShamRack で偽装されるため, Excon (Socket) で通信する
    class Application
      def app
        request = Rack::Request.new(env)
        options = {}
        options[:proxy] = ENV['HTTP_PROXY'] if ENV['HTTP_PROXY']

        # T.B.D : Request Header, Body, Methodの指定が必要
        res = Excon.get(request.url, options)
        [ res.status, res.headers, [ res.body ] ]
      end
    end
  end
end
