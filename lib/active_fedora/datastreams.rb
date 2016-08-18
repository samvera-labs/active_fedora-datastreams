require "active_fedora/datastreams/version"
require 'active_fedora'

module ActiveFedora
  autoload :NomDatastream, 'active_fedora/nom_datastream'
  autoload :OmDatastream, 'active_fedora/om_datastream'
  autoload :QualifiedDublinCoreDatastream, 'active_fedora/qualified_dublin_core_datastream'

  module Datastreams
    extend ActiveSupport::Autoload
    autoload :NokogiriDatastreams, 'active_fedora/datastreams/nokogiri_datastreams'
  end

  module RDF
    autoload :DatastreamIndexing, 'active_fedora/rdf/datastream_indexing'
  end

  autoload :NtriplesRDFDatastream, 'active_fedora/rdf/ntriples_rdf_datastream'
  autoload :RDFDatastream, 'active_fedora/rdf/rdf_datastream'
  autoload :RDFXMLDatastream, 'active_fedora/rdf/rdfxml_datastream'
end
