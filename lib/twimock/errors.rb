module Twimock
  module Errors
    class Error < StandardError; end
    class ColumnTypeNotNull < Error; end
    class IncorrectDataFormat < Error; end
  end
end
