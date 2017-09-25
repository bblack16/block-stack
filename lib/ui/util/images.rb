module BlockStack
  # Image related helpers for UI servers running sprockets.
  module ImageHelper
    def image_tags(*images, **opts)
      images.map do |image|
        if self.class.opal.sprockets.find_asset("images/#{image}")
          tag(:img, '', opts.except(:fallbacks, :missing).merge(src: "/assets/images/#{image}"))
        else
          fallbacks = opts[:fallbacks]
          return opts[:missing] unless fallbacks && !fallbacks.empty?
          image_tags(fallbacks.first, **opts.merge(fallbacks: fallbacks[1..-1]))
        end
      end.compact.join
    end

    alias_method :image_tag, :image_tags

    def find_image(*images)
      images.find { |image| self.class.opal.sprockets.find_asset("images/#{image}") }
    end

    def image?(image)
      find_image(image) ? true : false
    end
  end
end
