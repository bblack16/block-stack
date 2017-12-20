require 'digest'
require_relative 'provider'

module BlockStack
  module Encryption
    extend BBLib::Attrs

    attr_ary_of Encryption::Provider, :providers, default_proc: :all_providers, singleton: true, add_rem: true
    attr_sym :default_provider, default: :sha2, singleton: true

    def self.encrypt(key, type = default_provider)
      provider_for(type).encrypt(key)
    end

    def self.match?(key, encrypted, type = default_provider)
      provider_for(type).match?(key, encrypted)
    end

    def self.provider_for(type)
      providers.find { |pr| pr.type == type }
    end

    def self.all_providers
      Provider.descendants.map(&:new)
    end
  end
end
