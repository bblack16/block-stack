module BlockStack
  def self.load_all(path, recursive: true)
    BBLib.scan_files(path, '*.rb', recursive: recursive) do |file|
      require_relative file
    end
  end
end
