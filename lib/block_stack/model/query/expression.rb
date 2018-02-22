module BlockStack
  class Query

    class Expression
      include BBLib::Effortless
      OPERATORS = {
        equal:                 ['=', '==', 'is', 'equals', /(is\s)?equal to/i],
        not_equal:             ['!=', '!:', /isn\'?t|(is\s)?not equal(\sto)?/],
        like:                  ['~', '~~', /(is\s)?like/],
        greater_than:          ['gt', '>', /(is\s)?greater than/],
        less_than:             ['lt', '<', /(is\s)?less than/],
        greater_than_or_equal: ['gt', '=>', /(is\s)?greater than or equal to/],
        less_than_or_equal:    ['gt', '<=', /(is\s)?less than or equal to/]
      }

      attr_element_of OPERATORS, :operator

      def self.parse(expression)
        expression.qsplit(*AND_EXPRESSION_DIVIDERS).map do |sub_exp|
          sub_exp.qsplit(*OR_EXPRESSION_DIVIDERS).map do |sexp|
            sexp
          end
        end
      end
    end
  end
end
