module BlockStack
  module Authentication
    class Custom < Source
      attr_of Proc, :custom, required: true, arg_at: 0

      def credentials(request, params)
        custom.call(request, params)
      end

    end
  end
end
