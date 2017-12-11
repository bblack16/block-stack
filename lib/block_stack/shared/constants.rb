module BlockStack
  VERSION = '1.0.0'.freeze
  VERBS   = [:get, :post, :put, :delete, :patch, :head, :options, :link, :unlink].freeze
  HTML    = BBLib::HTML
  Tag     = BBLib::HTML::Tag
end
