require "om"

module ActiveFedora
  class OmDatastream < File
    # before_save do
    #   if content.blank?
    #     ActiveFedora::Base.logger.warn "Cowardly refusing to save a datastream with empty content: #{self.inspect}"
    #     false
    #   end
    # end

    include OM::XML::Document
    include OM::XML::TerminologyBasedSolrizer # this adds support for calling .to_solr
    include Datastreams::NokogiriDatastreams

    alias om_term_values term_values unless method_defined?(:om_term_values)
    alias om_update_values update_values unless method_defined?(:om_update_values)

    def default_mime_type
      'text/xml'
    end

    # Indicates that this datastream has metadata content.
    # @return true
    def metadata?
      true
    end

    # Return a hash suitable for indexing in solr. Every field name is prefixed with the
    # value returned by the +prefix+ method.
    def to_solr(solr_doc = {}, opts = {})
      prefix = self.prefix(opts[:name])
      solr_doc.merge super({}).each_with_object({}) { |(key, value), new| new[[prefix, key].join] = value }
    end

    # Update field values within the current datastream using {#update_values}, which is a wrapper for {http://rdoc.info/gems/om/1.2.4/OM/XML/TermValueOperators#update_values-instance_method OM::TermValueOperators#update_values}
    # Ignores any fields from params that this datastream's Terminology doesn't recognize
    #
    # @param [Hash] params The params specifying which fields to update and their new values.  The syntax of the params Hash is the same as that expected by
    #         term_pointers must be a valid OM Term pointers (ie. [:name]).  Strings will be ignored.
    # @param [Hash] _opts This is not currently used by the datastream-level update_indexed_attributes method
    #
    # Example:
    #   @mods_ds.update_indexed_attributes( {[{":person"=>"0"}, "role"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} })
    #   => {"person_0_role"=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}}
    #
    #   @mods_ds.to_xml # (the following is an approximation)
    #   <mods>
    #     <mods:name type="person">
    #     <mods:role>
    #       <mods:roleTerm>role1</mods:roleTerm>
    #     </mods:role>
    #     <mods:role>
    #       <mods:roleTerm>role2</mods:roleTerm>
    #     </mods:role>
    #     <mods:role>
    #       <mods:roleTerm>role3</mods:roleTerm>
    #     </mods:role>
    #     </mods:name>
    #   </mods>
    def update_indexed_attributes(params = {}, _opts = {})
      raise "No terminology is set for this OmDatastream class.  Cannot perform update_indexed_attributes" if self.class.terminology.nil?
      # remove any fields from params that this datastream doesn't recognize
      # make sure to make a copy of params so not to modify hash that might be passed to other methods
      current_params = params.clone
      current_params.delete_if do |term_pointer, new_values|
        if term_pointer.is_a?(String)
          ActiveFedora::Base.logger&.warn "WARNING: #{self.class.name} ignoring {#{term_pointer.inspect} => #{new_values.inspect}} because #{term_pointer.inspect} is a String (only valid OM Term Pointers will be used).  Make sure your html has the correct field_selector tags in it."
          true
        else
          !self.class.terminology.has_term?(*OM.destringify(term_pointer))
        end
      end

      result = {}
      result = update_values(current_params) unless current_params.empty?

      result
    end

    def get_values(field_key, _default = [])
      term_values(*field_key)
    end

    def find_by_terms(*termpointer)
      super
    end

    # Update values in the datastream's xml
    # This wraps {http://rdoc.info/gems/om/1.2.4/OM/XML/TermValueOperators#update_values-instance_method OM::TermValueOperators#update_values} so that returns an error if we have loaded from solr since datastreams loaded that way should be read-only
    #
    # @example Updating multiple values with a Hash of Term pointers and values
    #   ds.update_values( {[{":person"=>"0"}, "role", "text"]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}, [{:person=>1}, :family_name]=>"Andronicus", [{"person"=>"1"},:given_name]=>["Titus"],[{:person=>1},:role,:text]=>["otherrole1","otherrole2"] } )
    #   => {"person_0_role_text"=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"}, "person_1_role_text"=>{"0"=>"otherrole1", "1"=>"otherrole2"}}
    def update_values(params = {})
      raise "can't modify frozen #{self.class}" if frozen?
      ng_xml_will_change!
      result = om_update_values(params)
      result
    end

    protected

      # The string to prefix all solr fields with. Override this method if you want
      # a prefix other than the default
      def prefix(path)
        path ? "#{path.underscore}__" : ''
      end
  end
end
