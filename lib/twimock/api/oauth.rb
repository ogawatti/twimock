module Twimock
  module API
    class OAuth
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call
      end
    end
  end
end
