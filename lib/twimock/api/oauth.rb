module Twimock
  module API
    class OAuth
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      end

      private

      def unauthorized
        [ "401 Unauthorized", {}, "" ]
      end
    end
  end
end
