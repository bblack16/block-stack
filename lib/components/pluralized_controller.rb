module BlockStack
  class PluralizedController < Controller

    def self.route_prefix
      self.to_s.split('::').last.sub(/Controller$/, '').method_case.pluralize
    end

    def self.api_route_prefix
      "api/#{route_prefix}"
    end

  end
end
