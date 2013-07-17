# encoding: utf-8
require 'spec_helper'

describe StrToHash do
  let(:parser) { ParamsHashParser.new }
  let(:parse_tree) { parser.parse(example.description) }
  describe "::hash" do

    {
      '{"bee"=>"bop"}' => {'bee' => 'bop'},
      '{"bee"=>"bop", "bing"=>"bang"}' => {'bee' => 'bop', 'bing' => 'bang'},
      '{"bee"=>{"bim"=>"bop"}}' => {'bee' => {'bim' => 'bop'}},
      '{"foo"=>"bar", "black"=>"white", "up"=>"down", "yellow"=>"cherries", "bee"=>{"bim"=>"bop"}}' => {'foo' => 'bar', 'up' => 'down', 'yellow' => 'cherries', 'black' => 'white', 'bee' => {'bim' => 'bop'}},
      '{"little"=>{"russian"=>{"dolls"=>{"nest"=>{"very"=>"deeply"}}}}}' => {'little' => {'russian' => {'dolls' => {'nest' => {'very' => 'deeply'}}}}},
      '{"bee"=>{"bim"=>"bop"}, "mu"=>"shu", "abra"=>{"ca"=>"dabra"}, "chicken"=>{"noodle"=>{"soup"=>"goop"}, "grey"=>"cheese"}}'=> {'bee' => {'bim' => 'bop'}, 'mu' => 'shu', 'abra' => {'ca' => 'dabra'}, 'chicken' => {'noodle' => {'soup' => 'goop'}, 'grey' => 'cheese'}},
      '{"binder"=>{"name"=>"CF Binder"}}' => {"binder"=>{"name"=>"CF Binder"}},
      '{"authenticity_token"=>"FfrigJj4WBs+iuoNlH1vlojQyvhj2Ce7NSMo7RMcvqo=", "binder"=>{"name"=>"CF Binder"}}' => { "authenticity_token"=>"FfrigJj4WBs+iuoNlH1vlojQyvhj2Ce7NSMo7RMcvqo=", "binder"=>{"name"=>"CF Binder"}},
      '{"utf8"=>"✓", "authenticity_token"=>"FfrigJj4WBs+iuoNlH1vlojQyvhj2Ce7NSMo7RMcvqo=", "binder"=>{"name"=>"CF Binder"}}' => {"utf8"=>"✓", "authenticity_token"=>"FfrigJj4WBs+iuoNlH1vlojQyvhj2Ce7NSMo7RMcvqo=", "binder"=>{"name"=>"CF Binder"}},
      '{"dataset_ids"=>["", "3"]}' => {'dataset_ids' => ['', '3']}
    }.each do |str, hash|
      it str do
        StrToHash.hash(parse_tree).should == hash
      end
    end



    it '"foo" should raise an error' do
      lambda {StrToHash.hash('foo')}.should raise_error(StrToHash::BadSyntaxNodeError)
    end
  end

  describe "::key_value_list" do
    let(:list) { parser.parse('{"foo"=>"bar", "bee"=>"bop", "bam"=>"bam"}').elements[1] }
    it "has two elements" do
      list.elements.length.should == 2
    end

    it "first element is a key-val pair" do
      list.elements[0].rule.should == 'KeyValPair'
    end

    it "last element contains a list of key-val lists" do
      list.elements[1].elements[0].rule.should == 'KeyValList'
    end
  end

  describe "::parse" do
    it "takes a string and returns a hash" do
      StrToHash.parse('{"foo"=>"boo"}').should == {"foo" => "boo"}
    end

    it "returns nil if the hash was invalid" do
      StrToHash.parse(nil).should == nil
      StrToHash.parse('foo').should == nil
      StrToHash.parse('{"foo=>"boo"}').should == nil
      #                    ^----- missing a quotation mark
    end
  end
end
