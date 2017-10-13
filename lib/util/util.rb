module BlockStack
  VERBS = [:get, :post, :put, :delete, :patch, :head, :options, :link, :unlink]

  def self.logger(new_logger = nil)
    return @logger = new_logger if new_logger
    @logger ||= BBLib.logger
  end

  def self.build_dir(path)
    return false unless Dir.exist?(path)
    dirs = [
      '/app/javascript', '/app/stylesheets', '/app/images', '/app/fonts',
      '/app/views', '/app/models', '/app/controllers', '/public'
    ]
    path = path[0..-2] if path.end_with?('/')
    logger.info("Building app paths at #{path}")
    dirs.all? do |d|
      pth = "#{path}#{d}"
      FileUtils.mkdir_p(pth)
      Dir.exist?(pth)
    end
  end
end
