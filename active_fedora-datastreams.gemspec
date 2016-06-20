# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_fedora/datastreams/version'

Gem::Specification.new do |spec|
  spec.name          = "active_fedora-datastreams"
  spec.version       = ActiveFedora::Datastreams::VERSION
  spec.authors       = ["Justin Coyne"]
  spec.email         = ["jcoyne@justincoyne.com"]

  spec.summary       = %q{Datastreams for ActiveFedora}
  spec.description   = %q{XML and RDF datastreams for ActiveFedora}
  spec.homepage      = "https://github.com/projecthydra-labs/active_fedora-datastreams"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "active-fedora", "~> 10.0"
  spec.add_dependency "om", "~> 3.1"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
