module Twimock
  module Errors
    class Error < StandardError; end
    class ColumnTypeNotNull < Error; end
    class IncorrectDataFormat < Error; end
    class InvalidRequestToken < Error; end
    class InvalidConsumerKey < Error; end
    class InvalidAccessToken < Error; end
    class InvalidUsernameOrEmail < Error; end
    class InvalidPassword < Error; end
    class ApplicationNotFound < Error; end
    class OAuthCancelled < Error; end
    class InternalServerError < Error; end
  end
end
