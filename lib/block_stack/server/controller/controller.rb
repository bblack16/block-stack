module BlockStack
  class Controller < Server

    attr_of Server, :base_server, singleton: true

    def self.controllers
      []
    end

  end
end
