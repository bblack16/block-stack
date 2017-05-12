require_relative 'csv'
require_relative 'json'
require_relative 'xml'
require_relative 'yaml'

module BlockStack
  module Formatters
    module Text
      def self.process(response, request, params)
        response.body = response.body.to_s
      end
    end
  end
end
