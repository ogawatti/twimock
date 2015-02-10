module Twimock
  module Errors
    class Error < StandardError; end
    class ColumnTypeNotNull < Error; end
    class IncorrectDataFormat < Error; end
    class InvalidRequestToken < Error; end
    class InvalidUsernameOrEmail < Error; end
    class InvalidPassword < Error; end
  end
end
