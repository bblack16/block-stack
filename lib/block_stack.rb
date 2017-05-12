require_relative "block_stack/version"

require 'yaml'
require 'json'
require 'bblib' unless defined?(BBLib::VERSION)
require 'sinatra/base'
# require 'graphql'
# require 'rom'
require 'gyoku'

module BlockStack
  VERBS = [:get, :post, :put, :delete, :patch, :head, :options, :link, :unlink]
end

require_relative 'server/server'
require_relative 'formatter/formatter'
