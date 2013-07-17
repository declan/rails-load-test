require File.expand_path('app', File.dirname(__FILE__))

parser = LogParser.new(ARGV[0])
parser.parse

