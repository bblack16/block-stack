module BlockStack

  def self.settings
    @settings ||= default_settings
  end

  def self.setting(key)
    settings[key.to_sym]
  end

  def self.default_settings
    BBLib::HashStruct.new.tap do |settings|
      settings.default_controller = BlockStack::Controller
      settings.authentication = false
    end
  end

end
