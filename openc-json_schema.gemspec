require File.expand_path('../lib/openc/json_schema/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name    = "openc-json_schema"
  gem.version = Openc::JsonSchema::VERSION

  gem.author      = "OpenCorporates"
  gem.email       = "info@opencorporates.com"
  gem.homepage    = "https://github.com/openc/openc-json_schema"
  gem.summary     = "Utilities for validating JSON"
  gem.license     = "MIT"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency "json-schema", "~> 2.6.0"
  gem.add_dependency "json-pointer"

  gem.add_development_dependency "coveralls"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 3.0"
end
