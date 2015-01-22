module TestApplicationHelper
  extend self

  class TestRackApplication
    def call(env)
      [ 200, {}, [] ]
    end
  end
end
