module ActiveFedora
  #This class represents a Qualified Dublin Core Datastream. A special case of ActiveFedora::MetdataDatastream
  #The implementation of this class defines the terms from the Qualified Dublin Core specification.
  #This implementation features customized xml generators and deserialization routines to handle the 
  #Fedora Dublin Core XML datastreams structure.
  #
  #Fields can still be overridden if more specificity is desired (see ActiveFedora::Datastream#fields method).
  class QualifiedDublinCoreDatastream < MetadataDatastream
    
    #A frozen array of Dublincore Terms.
    DCTERMS = [
      :contributor, :coverage, :creator,  :description, :format, :identifier, :language, :publisher, :relation,  :source, :title, :abstract, :accessRights, :accrualMethod, :accrualPeriodicity, :accrualPolicy, :alternative, :audience, :available, :bibliographicCitation, :conformsTo, :contributor, :coverage, :created, :creator, :date, :dateAccepted, :dateCopyrighted, :dateSubmitted, :description, :educationLevel, :extent, :format, :hasFormat, :hasPart, :hasVersion, :identifier, :instructionalMethod, :isFormatOf, :isPartOf, :isReferencedBy, :isReplacedBy, :isRequiredBy, :issued, :isVersionOf, :language, :license, :mediator, :medium, :modified, :provenance, :publisher, :references, :relation, :replaces, :requires, :rights, :rightsHolder, :source, :spatial, :subject, :tableOfContents, :temporal, :type, :valid
    ]
    DCTERMS.freeze
    
    #Constructor. this class will call self.field for each DCTERM. In short, all DCTERMS fields will already exist
    #when this method returns. Each term is marked as a multivalue string.
    def initialize(digital_object, dsid, exists_in_fedora=false )
      super(digital_object, dsid)
      DCTERMS.each do |el|
        field el, :string, :multiple=>true
      end
      ###TODO this is loading eagerly, but we could make it lazy
      self.class.from_xml(exists_in_fedora ? content : nil, self)
      self
    end
    
    # Populate a QualifiedDublinCoreDatastream object based on the "datastream" node from a FOXML file
    # @param [String] node the xml from the content.  Assumes that the content of this datastream is that of an ActiveFedora QualifiedDublinCoreDatastream 
    # @param [ActiveFedora::Datastream] tmpl the Datastream object that you are building
    def self.from_xml(xml, tmpl) # :nodoc:
      return if xml.nil?
      node = Nokogiri::XML::Document.parse(xml)
      tmpl.fields.each do |z|
        fname = z.first
        fspec = z.last
        node_name = "dcterms:#{fspec[:xml_node] ? fspec[:xml_node] : fname}"
        attr_modifier= "[@xsi:type='#{fspec[:encoding]}']" if fspec[:encoding]
        query = "/dc/#{node_name}#{attr_modifier}"

        node.xpath(query).each do |f|
           tmpl.send("#{fname}_append", f.text)
        end

      end
      tmpl.instance_variable_set(:@dirty, false)
      tmpl
    end

  def to_xml() 
    to_dc_xml() 
  end

   #Render self as a Fedora DC xml document.
   def to_dc_xml
     #TODO: pull the modifiers up into MDDS
     xml = REXML::Document.new("<dc xmlns:dcterms='http://purl.org/dc/terms/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'/>")
     fields.each do |field_name,field_info|
       el = REXML::Element.new("dcterms:#{field_name.to_s}")
       if field_info.class == Hash
         field_info.each do |k, v|
           case k
           when :element_attrs
            v.each{|k,v| el.add_attribute(k.to_s, v.to_s)}
           when :values, :type
             # do nothing to the :values array
           when :xml_node
             el.name = "dcterms:#{v}"
           when :encoding, :encoding_scheme
             el.add_attribute("xsi:type", v)
           when :multiple
             next
           else
             el.add_attribute(k.to_s, v)
           end
         end
         field_info = field_info[:values]
       end
       field_info.each do |val|
         el = el.clone
         el.text = val.to_s
         xml.root.elements.add(el)
       end
     end
     return xml.to_s
   end

  end
end
