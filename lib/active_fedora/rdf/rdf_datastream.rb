require 'tempfile'

module ActiveFedora
  class RDFDatastream < File
    include ActiveTriples::NestedAttributes
    include RDF::DatastreamIndexing
    include ActiveTriples::Properties
    include ActiveTriples::Reflection

    delegate :rdf_subject, :set_value, :get_values, :attributes=, to: :resource

    class << self
      def rdf_subject(&block)
        return @subject_block = block if block_given?

        @subject_block ||= ->(ds) { parent_uri(ds) }
      end

      # Trim the last segment off the URI to get the parents uri
      def parent_uri(ds)
        m = /^(.*)\/[^\/]*$/.match(ds.uri)
        if m
          m[1]
        else
          ::RDF::URI.new(nil)
        end
      end

      ##
      # @param [Class] klass an object to set as the resource class, Must be a descendant of
      # ActiveTriples::Resource and include ActiveFedora::RDF::Persistence.
      #
      # @return [Class] the object resource class
      def resource_class(klass = nil)
        if klass
          raise ArgumentError, "#{self} already has a resource_class #{@resource_class}, cannot redefine it to #{klass}" if @resource_class && klass != @resource_class
          raise ArgumentError, "#{klass} must be a subclass of ActiveTriples::Resource" unless klass < ActiveTriples::Resource
        end

        @resource_class ||= begin
                              klass = Class.new(klass || ActiveTriples::Resource)
                              klass.send(:include, RDF::Persistence)
                              klass
                            end
      end
    end

    before_save do
      if content.blank?
        ActiveFedora::Base.logger&.warn "Cowardly refusing to save a datastream with empty content: #{inspect}"
        if ActiveSupport.respond_to?(:halt_callback_chains_on_return_false)
          # For Rails 5+
          throw :abort
        else
          # For Rails <= 4
          false
        end
      end
    end

    def parent_uri
      self.class.parent_uri(self)
    end

    def metadata?
      true
    end

    def content
      serialize
    end

    def content=(new_content)
      resource.clear!
      resource << deserialize(new_content)
      content
    end

    def uri=(uri)
      super
      resource.set_subject!(parent_uri) if empty_or_blank_subject?
    end

    def content_changed?
      return false unless instance_variable_defined? :@resource
      return true if empty_or_blank_subject? # can't be serialized because a subject hasn't been assigned yet.
      @content = serialize
      super
    end

    def empty_or_blank_subject?
      resource.rdf_subject.node? || resource.rdf_subject.value.blank?
    end

    def freeze
      @resource.freeze
    end

    ##
    # The resource is the RdfResource object that stores the graph for
    # the datastream and is the central point for its relationship to
    # other nodes.
    #
    # set_value, get_value, and property accessors are delegated to this object.
    def resource
      @resource ||= begin
                      klass = self.class.resource_class
                      klass.properties.merge(self.class.properties).each do |_prop, config|
                        klass.property(config.term,
                                       predicate: config.predicate,
                                       class_name: config.class_name)
                      end
                      klass.accepts_nested_attributes_for(*nested_attributes_options.keys) if nested_attributes_options.present?
                      uri_stub = self.class.rdf_subject.call(self)

                      r = klass.new(uri_stub)
                      r.datastream = self
                      r << deserialize
                      r
                    end
    end

    alias graph resource

    def refresh_attributes
      @resource = nil
    end

    ##
    # This method allows for delegation.
    # This patches the fact that there's no consistent API for allowing delegation - we're matching the
    # OmDatastream implementation as our "consistency" point.
    # @TODO: We may need to enable deep RDF delegation at one point.
    def term_values(*values)
      send(values.first)
    end

    def update_indexed_attributes(hash)
      hash.each do |fields, value|
        fields.each do |field|
          send("#{field}=", value)
        end
      end
    end

    def serialize
      resource.set_subject!(parent_uri) if parent_uri && rdf_subject.node?
      resource.dump serialization_format
    end

    def deserialize(data = nil)
      return ::RDF::Graph.new if new_record? && data.nil?
      data ||= remote_content

      # Because datastream_content can return nil, we should check that here.
      return ::RDF::Graph.new if data.nil?

      data.force_encoding('utf-8')
      ::RDF::Graph.new << ::RDF::Reader.for(serialization_format).new(data)
    end

    def serialization_format
      raise "you must override the `serialization_format' method in a subclass"
    end
  end
end
