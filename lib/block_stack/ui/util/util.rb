module BlockStack
  def self.build_folders(path)
    folders = [
      '/app/views',
      '/app/javascript',
      '/app/stylesheets',
      '/app/font',
      '/app/images',
      '/app/models',
      '/app/controllers'
    ]

    folders.all? do |folder|
      FileUtils.mkpath("#{path}#{folder}".pathify)
    end
  end
end
