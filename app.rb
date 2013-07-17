Dir['./config/**/*.rb'].each { |f| require f }
require File.expand_path('lib/rails_load_test', File.dirname(__FILE__))
