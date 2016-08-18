require "active_fedora/datastreams/version"
require 'active_fedora'

module ActiveFedora
  module Datastreams
    extend ActiveSupport::Autoload
    autoload :NokogiriDatastreams, 'active_fedora/datastreams/nokogiri_datastreams'
  end
end
