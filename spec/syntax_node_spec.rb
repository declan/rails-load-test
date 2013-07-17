require 'spec_helper'

describe Treetop::Runtime::SyntaxNode do
  let(:parse_tree) { ParamsHashParser.new.parse('{"baz"=>{"bee"=>"bop"}}') }
  describe "#rule" do
    it 'root is a hash' do
      parse_tree.rule.should == 'Hash'
    end

    it 'contents of a hash is a KeyValList' do
      parse_tree.elements[1].rule.should == 'KeyValList'
    end

    it 'first element of KeyValList is a KeyValPair' do
      parse_tree.elements[1].elements[0].rule.should == 'KeyValPair'
    end

    it 'first element of KeyValPair is a Str' do
      parse_tree.elements[1].elements[0].elements[0].rule.should == 'Str'
    end

    it 'third element of KeyValPair is a Hash (in this case)' do
      parse_tree.elements[1].elements[0].elements[2].rule.should == 'Hash'
    end

    it 'contents of Val can be a Str too' do
      # Look at value in nested hash ("bop").
      parse_tree.elements[1].elements[0].elements[2].elements[1].elements[0].elements[2].rule.should == 'Str'
    end
  end
end
