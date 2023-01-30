# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_fedora/datastreams/version'

Gem::Specification.new do |spec|
  spec.name          = "active_fedora-datastreams"
  spec.version       = ActiveFedora::Datastreams::VERSION
  spec.authors       = ["Justin Coyne"]
  spec.email         = ["jcoyne@justincoyne.com"]

  spec.summary       = 'Datastreams for ActiveFedora'
  spec.description   = 'XML and RDF datastreams for ActiveFedora'
  spec.homepage      = "https://github.com/projecthydra-labs/active_fedora-datastreams"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "active-fedora", ">= 11.0.0.pre"
  spec.add_dependency "activemodel", ">= 5.2"
  spec.add_dependency "om", "~> 3.1"
  spec.add_dependency "nom-xml", ">= 0.5.1"
  spec.add_dependency "rdf-rdfxml", '~> 3.2'
  spec.add_dependency "rdf", "~> 3.2"
  spec.add_development_dependency "bixby"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency "equivalent-xml"
  spec.add_development_dependency 'fcrepo_wrapper'
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency "solr_wrapper"
end
