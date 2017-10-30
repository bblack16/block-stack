module BlockStack

  def self.logger
    @logger ||= BBLib.logger
  end

  def self.logger=(logger)
    @logger = logger
  end

end
