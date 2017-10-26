module BlockStack
  module ServerHelpers

    def format
      formatter = pick_formatter(request, params)
      formatter ? [formatter.format].flatten.first : :html
    end

  end
end
