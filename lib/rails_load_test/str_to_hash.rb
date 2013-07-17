# Monkey patch the syntax nodes so they can tell us what they are.
class Treetop::Runtime::SyntaxNode
  def rule
    if extension_modules.length > 0
      extension_modules[0].to_s.split('::')[1].sub(/\d*$/,'')
    else
      nil
    end
  end
end

module StrToHash
  class BadSyntaxNodeError < StandardError; end

  class << self

    def parser
      @parser ||= ParamsHashParser.new
    end

    def parse(str)
      begin
        hash(parser.parse(str))
      rescue
        nil
      end
    end

    def hash(parse_tree)
      check_rule(parse_tree, 'Hash')
      key_val_list(parse_tree.elements[1])
    end

    def key_val_list(parse_tree)
      check_rule(parse_tree, 'KeyValList')
      key, val = key_val_pair(parse_tree.elements.first)
      if parse_tree.elements.last.elements.length == 0
        {key => val}
      else
        hash = _key_val_list_helper(parse_tree.elements.last)
        hash[key] = val
        hash
      end
    end

    def _key_val_list_helper(parse_tree)
      parse_tree.elements.reduce({}) do |hash, list|
        key, val = key_val_pair(list.elements[1])
        hash[key] = val
        hash
      end
    end

    def key_val_pair(parse_tree)
      check_rule(parse_tree, 'KeyValPair')
      key = str(parse_tree.elements[0])
      val = val(parse_tree.elements[2])
      [key, val]
    end

    def str(parse_tree)
      check_rule(parse_tree, 'Str')
      parse_tree.elements[1].text_value
    end

    def val(parse_tree)
      if parse_tree.rule == 'Hash'
        hash(parse_tree)
      else
        str(parse_tree)
      end
    end

    def check_rule(parse_tree,rule)
      raise BadSyntaxNodeError.new("This is not a #{rule}!") unless parse_tree.respond_to?(:rule) and parse_tree.rule == rule
    end
  end
end
