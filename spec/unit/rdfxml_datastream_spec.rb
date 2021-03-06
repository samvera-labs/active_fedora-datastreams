require 'spec_helper'

describe ActiveFedora::RDFXMLDatastream do
  describe "a new instance" do
    subject(:my_datastream) { MyRdfxmlDatastream.new }
    before(:each) do
      class MyRdfxmlDatastream < ActiveFedora::RDFXMLDatastream
        property :publisher, predicate: ::RDF::Vocab::DC.publisher
      end
      allow(my_datastream).to receive(:id).and_return('test:1')
    end

    after(:each) do
      Object.send(:remove_const, :MyRdfxmlDatastream)
    end

    it "saves and reload" do
      my_datastream.publisher = ["St. Martin's Press"]
      expect(my_datastream.serialize).to match(/<rdf:RDF/)
    end
  end

  describe "a complex data model" do
    before do
      class DAMS < RDF::Vocabulary("http://library.ucsd.edu/ontology/dams#")
        property :title
        property :relatedTitle
        property :type
        property :date
        property :beginDate
        property :endDate
        property :language
        property :typeOfResource
        property :otherResource
        property :RelatedResource
        property :description
        property :uri
        property :relationship
        property :Relationship
        property :role
        property :name
        property :assembledCollection
        property :Object
        property :value
      end

      module RDF
        # This enables RDF to respond_to? :value
        def self.value
          self[:value]
        end
      end

      class MyDatastream < ActiveFedora::RDFXMLDatastream
        property :resource_type, predicate: DAMS.typeOfResource
        property :title, predicate: DAMS.title, class_name: 'Description'

        rdf_subject { |ds| RDF::URI.new(ds.about) }

        attr_accessor :about

        def initialize(options = {})
          @about = options.delete(:about)
          super
        end

        class Description < ActiveTriples::Resource
          configure type: DAMS.Description
          property :value, predicate: ::RDF.value do |index|
            index.as :searchable
          end
        end
      end
    end

    after do
      Object.send(:remove_const, :MyDatastream)
      Object.send(:remove_const, :DAMS)
    end

    describe "a new instance" do
      let(:my_datastream) { MyDatastream.new(about: "http://library.ucsd.edu/ark:/20775/") }
      it "has a subject" do
        expect(my_datastream.rdf_subject.to_s).to eq "http://library.ucsd.edu/ark:/20775/"
      end
    end

    describe "an instance with content" do
      let(:my_datastream) do
        my_datastream = MyDatastream.new(about: "http://library.ucsd.edu/ark:/20775/")
        my_datastream.content = File.new('spec/fixtures/damsObjectModel.xml').read
        my_datastream
      end
      it "has a subject" do
        expect(my_datastream.rdf_subject.to_s).to eq "http://library.ucsd.edu/ark:/20775/"
      end
      it "has mimeType" do
        expect(my_datastream.mime_type).to eq 'text/xml'
      end
      it "has fields" do
        expect(my_datastream.resource_type).to eq ["image"]
        expect(my_datastream.title.first.value).to eq ["example title"]
      end
    end
  end
end
