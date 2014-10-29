module Twimock
  module Errors
    class Error < StandardError; end
    class ColumnTypeNotNull < Error; end
  end
end
