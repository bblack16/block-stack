require_relative 'expression'

module BlockStack
  class Query
    OR_EXPRESSION_DIVIDERS = %w{or ||}
    AND_EXPRESSION_DIVIDERS = ['and', '&&', '+', '&']

    include BBLib::Effortless

    attr_str :raw_expression, arg_at: 0



  end
end
