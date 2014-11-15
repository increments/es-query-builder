lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "es-query-builder/version"

Gem::Specification.new do |spec|
  spec.name          = "es-query-builder"
  spec.version       = EsQueryBuilder::VERSION
  spec.authors       = ["Yuku Takahashi"]
  spec.email         = ["yuku@qiita.com"]
  spec.summary       = "Build a query hash by a simple query string"
  spec.homepage      = "https://github.com/increments/es-query-builder"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
