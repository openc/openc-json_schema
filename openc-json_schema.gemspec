# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openc/json_schema/version'

Gem::Specification.new do |spec|
  spec.name          = "openc-json_schema"
  spec.version       = Openc::JsonSchema::VERSION

  spec.author        = "OpenCorporates"
  spec.email         = "info@opencorporates.com"
  spec.summary       = "Utilities for validating JSON"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "json-schema-openc-fork", "0.0.1"
end
