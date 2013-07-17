# encoding: utf-8
require 'spec_helper'

describe ParamsHashParser do
  let(:parser) { ParamsHashParser.new }
  %w[
    {"foo"=>"bar"}
    {"foo"=>"bar",\ "bee"=>"bop",\ "upside"=>"down"}
    {"foo"=>"2"}
    {"foo"=>{"bar"=>"bop"}}
    {"foo"=>"Forest\ Gump"}
    {"utf8"=>"✓"}
    {"authenticity_token"=>"FfrigJj4WBs+iuoNlH1vlojQyvhj2Ce7NSMo7RMcvqo="}
    {"authenticity_token"=>"5S2mvHj30IQVH+rWS+kixnI/mbw6/sIY258yNQVP3SU="}
    {"program_id"=>"tumbling-4-success",\ "id"=>"6144"}
    {"email"=>"bob@purplebinder.com"}
    {"password"=>"[FILTERED]"}
    {"foo"=>"bar!"}
    {"foo"=>"bar?"}
    {"foo"=>""}
    {"utf8"=>"✓",\ "authenticity_token"=>"5S2mvHj30IQVH+rWS+kixnI/mbw6/sIY258yNQVP3SU=",\ "user"=>{"email"=>"vvences@howardarea.org",\ "password"=>"[FILTERED]"}}
    {"url"=>"http://4chan.org"}
    {"dataset_ids=>["3"]}
    {"dataset_ids=>["",\ "3"]}
  ].each do |hash_str|
    it hash_str do
      parser.parse(hash_str).should be_a(Treetop::Runtime::SyntaxNode)
    end
  end
end
