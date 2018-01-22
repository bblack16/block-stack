module BlockStack
  module Authentication
    class Param < Source
      attr_ary_of [String], :params, default: ['user', 'password'], pre_proc: proc { |x| [x].flatten.map(&:to_s) }

      def credentials(request, params)
        self.params.map do |param|
          return false unless params.include?(param)
          params[param]
        end
      rescue => _e
        false
      end
    end
  end
end
