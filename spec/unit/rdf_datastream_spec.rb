# -*- encoding: utf-8 -*-
require 'spec_helper'

describe ActiveFedora::RDFDatastream do
  describe "a new instance" do
    subject { described_class.new }
    it { should be_metadata }
    it { should_not be_content_changed }
  end

  describe "an instance that exists in the datastore, but hasn't been loaded" do
    before do
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        property :title, predicate: ::RDF::Vocab::DC.title
        property :description, predicate: ::RDF::Vocab::DC.description
      end

      class MyObj < ActiveFedora::Base
        has_subresource 'descMetadata', class_name: 'MyDatastream'
      end
      @obj = MyObj.new
      @obj.descMetadata.title = 'Foobar'
      @obj.save
    end
    after do
      @obj.destroy
      Object.send(:remove_const, :MyDatastream)
      Object.send(:remove_const, :MyObj)
    end

    subject(:desc_metadata) { @obj.reload.descMetadata }

    it "does not load the descMetadata datastream when calling content_changed?" do
      expect(desc_metadata).to_not receive(:retrieve_content)
      expect(desc_metadata).to_not be_content_changed
    end

    it "allows asserting an empty string" do
      desc_metadata.title = ['']
      expect(desc_metadata.title).to eq ['']
    end

    it "clears stuff" do
      desc_metadata.title = ['one', 'two', 'three']
      desc_metadata.title.clear
      expect(desc_metadata.graph.query([desc_metadata.rdf_subject, ::RDF::Vocab::DC.title, nil]).first).to be_nil
    end

    it "has a list of fields" do
      expect(MyDatastream.fields).to eq [:title, :description]
    end
  end

  describe "deserialize" do
    subject(:datastream) { ActiveFedora::NtriplesRDFDatastream.new }
    it "is able to handle non-utf-8 characters" do
      # see https://github.com/ruby-rdf/rdf/issues/142
      data = "<info:fedora/scholarsphere:qv33rx50r> <http://purl.org/dc/terms/description> \"\\n\xE2\x80\x99 \" .\n".force_encoding('ASCII-8BIT')

      result = datastream.deserialize(data)
      expect(result.dump(:ntriples)).to eq "<info:fedora/scholarsphere:qv33rx50r> <http://purl.org/dc/terms/description> \"\\n’ \" .\n"
    end
  end

  describe 'content=' do
    let(:ds) { ActiveFedora::NtriplesRDFDatastream.new }
    it "is able to handle non-utf-8 characters" do
      data = "<info:fedora/scholarsphere:qv33rx50r> <http://purl.org/dc/terms/description> \"\\n\xE2\x80\x99 \" .\n".force_encoding('ASCII-8BIT')
      ds.content = data
      expect(ds.resource.dump(:ntriples)).to eq "<info:fedora/scholarsphere:qv33rx50r> <http://purl.org/dc/terms/description> \"\\n’ \" .\n"
    end
  end

  describe 'legacy non-utf-8 characters' do
    let(:ds) do
      ActiveFedora::NtriplesRDFDatastream.new.tap do |datastream|
        allow(datastream).to receive(:new_record?).and_return(false)
        allow(datastream).to receive(:remote_content).and_return("<info:fedora/scholarsphere:qv33rx50r> <http://purl.org/dc/terms/description> \"\\n\xE2\x80\x99 \" .\n".force_encoding('ASCII-8BIT'))
      end
    end
    it "does not error on access" do
      expect(ds.resource.dump(:ntriples)).to eq "<info:fedora/scholarsphere:qv33rx50r> <http://purl.org/dc/terms/description> \"\\n’ \" .\n"
    end
  end
end
