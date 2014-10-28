$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '.bundle/'
  add_filter '/spec/'
end

# spec/support 以下のヘルパーを読み込み
Dir[File.expand_path('../support/', __FILE__) + '/**/*.rb'].each {|f| require f}

require 'twimock'
