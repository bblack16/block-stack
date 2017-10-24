# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "block_stack/version"

Gem::Specification.new do |spec|
  spec.name          = "block_stack"
  spec.version       = BlockStack::VERSION
  spec.authors       = ["Brandon Black"]
  spec.email         = ["d2sm10@hotmail.com"]

  spec.summary       = %q{BlockStack is a Sinatra based web server that believes in doing more, with less boilerplate.}
  spec.description   = %q{BlockStack is a web framework built on top of the classy Sinatra. It's goals are to make building an API based web server fast and convenient.}
  spec.homepage      = "https://github.com/bblack16/block-stack"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "bblib", "~> 1.0"
  spec.add_runtime_dependency "sinatra", "~> 2.0"
  spec.add_runtime_dependency "gyoku", "~> 1.3"
end
