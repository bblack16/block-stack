require_relative 'param'

module BlockStack
  module Authentication
    class APIKey < Param

      protected

      def simple_setup
        self.params = ['api_key']
      end
    end
  end
end
