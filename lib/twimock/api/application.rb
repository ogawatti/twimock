require 'excon'

module Twimock
  module API
    # Rack Application
    # Net::HTTP は ShamRack で偽装されるため, Excon (Socket) で通信する
    class Application
      def call(env)
        request(env)
      end

      def request(env)
        rackreq = Rack::Request.new(env)
        connection = Excon.new(rackreq.url)

        options = {}
        options[:method]  = rackreq.request_method
        options[:path]    = rackreq.path
        options[:headers] = rackreq.env.select{|k,v| k !~ /^rack\./}
        options[:body]    = rackreq.body.read

        res = connection.request(options)
        [ res.status, res.headers, [ res.body ] ]
      end
    end
  end
end
