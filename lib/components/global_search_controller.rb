module BlockStack
  class GlobalSearchController < BlockStack::Controller
    def self.route_prefix
      nil
    end

    def self.base_server(server = nil)
      @base_server = server if server
      @base_server
    end

    get '/search' do
      @results = nil
      if params[:query]
        @results = BlockStack::Model.included_classes_and_descendants.flat_map do |model|
          next unless model.setting(:global_search)
          model.search(params[:query])
        end.compact.uniq.sort_by { |r| r._score }
      end
      slim :'defaults/global_search'
    end

    get_api '/search' do
      @results = nil
      if params[:query]
        @results = BlockStack::Model.included_classes_and_descendants.flat_map do |model|
          next unless model.setting(:global_search)
          model.search(params[:query])
        end.compact.uniq.sort_by { |r| r._score }
      end
    end
  end
end
