require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

# Some tentative extensions to ActiveFedora::Base

describe ActiveFedora::Base do
  
  @@last_pid = 0

  def increment_pid
    @@last_pid += 1    
  end
  
  before(:each) do
    @test_object = ActiveFedora::Base.new
  end

  after(:each) do
    begin
    @test_object.delete
    rescue
    end
  
    begin
    @test_object2.delete
    rescue
    end
    
    begin
    @test_object3.delete
    rescue
    end
  end
  
  it 'should provide #datastream_names' do
    @test_object.should respond_to(:datastream_names)
  end
  
  describe '#datastream_names' do
    class MockDatastreamNames < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"EAD", :type=>ActiveFedora::Datastream, :mimeType=>"application/xml", :controlGroup=>'M' 
    end
    
    it 'should return an array of datastream names defined by has_datastream' do
      @test_object2 = MockDatastreamNames.new
      @test_object2.datastream_names.should == ["thumbnail","EAD"]
    end
  end
  
  it 'should provide #add_named_datastream' do
    @test_object.should respond_to(:add_named_datastream)
  end
  
  describe '#add_named_datastream' do
    class MockAddNamedDatastream < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
      has_datastream :name=>"anymime", :type=>ActiveFedora::Datastream, :controlGroup=>'M' 
      has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E'
    end
      
    it 'should add a named datastream to a fedora object' do
      @test_object2 = MockAddNamedDatastream.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stubs(:original_filename).returns("dino.jpg")
      f.stubs(:content_type).returns("image/jpeg")
      #check cannot add a datastream with name that does not exist
      had_exception = false
      begin  
        @test_object2.add_named_datastream("thumb",{:content_type=>"image/jpeg",:blob=>f})
      rescue
        had_exception = true
      end
      raise "Did not raise exception with datastream name that does not exist" unless had_exception 
      #check that either blob or file opt must be set
      had_exception = false
      begin  
        @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg"})
      rescue
        had_exception = true
      end
      raise "Did not raise exception with blob not set" unless had_exception 
      
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f})
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:file=>f})
      #check dslabel set from either opt[label] or opt[blob].original_file_name
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2, :label=>"my_image"})
      @test_object2.high.first.dsLabel.should == "my_image"
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      @test_object2.high.first.dsLabel.should == "dino.jpg"
      #check opt[content_type] must be set or opt[blob] responds to content_type, already checking if content_type option set above
      f.expects(:content_type).returns("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:file=>f})
      had_exception = false
      begin
        @test_object2.add_named_datastream("thumbnail",{:file=>f2})
      rescue
        had_exception = true
      end
      raise "Did not raise exception if content_type not set" unless had_exception
      #check mimetype and content type must match if mimetype is specified (if not specified can be anything)
      f.stubs(:content_type).returns("image/tiff")
      had_exception = false
      begin
        @test_object2.add_named_datastream("thumbnail",{:file=>f})
      rescue
        had_exception = true
      end
      raise "Did not raise exception on content type and mime type mismatch" unless had_exception
      
      #check for if any mime type allowed
      @test_object2.add_named_datastream("anymime",{:file=>f})
      #check datastream created is of type ActiveFedora::Datastream
      @test_object2.anymime.first.class.should == ActiveFedora::Datastream
      #if dsid supplied check that conforms to prefix
      f.stubs(:content_type).returns("image/jpeg")
      had_exception = false
      begin
        @test_object2.add_named_datastream("thumbnail",{:file=>f,:dsid=>"DS1"})
      rescue
        had_exception = true
      end
      raise "Did not raise exception with dsid that does not conform to prefix" unless had_exception
      #if prefix not set check uses name in CAPS and dsid uses prefix
      #@test_object2.high.first.attributes[:prefix].should == "HIGH"
      @test_object2.high.first.dsid.match(/HIGH[0-9]/)
      #check datastreams added with other right properties
      @test_object2.high.first.controlGroup.should == "M"
      
      #check external datastream
      @test_object2.add_named_datastream("external",{:dsLocation=>"http://myreasource.com"})
      #check dslocation goes to dslabel
      @test_object2.external.first.dsLabel.should == "http://myreasource.com"
      #check datastreams added to fedora (may want to stub this at first)
      
    end
  end
  
  it 'should provide #add_named_file_datastream' do
    @test_object.should respond_to(:add_named_file_datastream)
  end
  
  describe '#add_named_file_datastream' do
    class MockAddNamedFileDatastream < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
      has_datastream :name=>"anymime", :type=>ActiveFedora::Datastream, :controlGroup=>'M' 
    end
    
    it 'should add a datastream as controlGroup M with blob set to file' do
      @test_object2 = MockAddNamedFileDatastream.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      #these normally supplied in multi-part post request
      f.stubs(:original_filename).returns("minivan.jpg")
      f.stubs(:content_type).returns("image/jpeg")
      @test_object2.add_named_file_datastream("thumbnail",f)
      thumb = @test_object2.thumbnail.first
      thumb.class.should == ActiveFedora::Datastream
      thumb.mimeType.should == "image/jpeg"
      thumb.dsid.should == "THUMB1"
      thumb.controlGroup.should == "M"
      thumb.dsLabel.should == "minivan.jpg"
      #thumb.name.should == "thumbnail"
        # :prefix=>"THUMB", :content_type=>"image/jpeg", :dsid=>"THUMB1", :dsID=>"THUMB1", 
        # :pid=>@test_object2.pid, :mimeType=>"image/jpeg", :controlGroup=>"M", :dsLabel=>"minivan.jpg", :name=>"thumbnail"}
      
    end
  end
  
  it 'should provide #update_named_datastream' do
    @test_object.should respond_to(:update_named_datastream)
  end
  
  describe '#update_named_datastream' do
    class MockUpdateNamedDatastream < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
    end
    
    it 'should update a datastream and not increment the dsid' do
      @test_object2 = MockUpdateNamedDatastream.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      f2.stubs(:content_type).returns("image/jpeg")
      f2.stubs(:original_filename).returns("dino.jpg")
      #check raise exception if dsid not supplied
      @test_object2.add_named_datastream("thumbnail",{:file=>f})
      had_exception = false
      begin
        @test_object2.update_named_datastream("thumbnail",{:file=>f})
      rescue
        had_exception = true
      end
      raise "Failed to raise exception if dsid not supplied" unless had_exception
      #raise exception if dsid does not exist
      had_exception = false
      begin
        @test_object2.update_named_datastream("thumbnail",{:file=>f,:dsid=>"THUMB100"})
      rescue
        had_exception = true
      end
      raise "Failed to raise exception if dsid does not exist" unless had_exception  
      #check datastream is updated in place without new dsid  
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      thumb1 = @test_object2.thumbnail.first
      thumb1.dsid.should == 'THUMB1'
      thumb1.pid.should == @test_object2.pid
      thumb1.dsLabel.should == 'minivan.jpg'
      f.rewind
      @test_object2.thumbnail.first.content.should == f.read
      @test_object2.update_named_datastream("thumbnail",{:file=>f2,:dsid=>"THUMB1"})
      @test_object2.thumbnail.size.should == 1
      @test_object2.thumbnail_ids == ["THUMB1"]
      # @test_object2.thumbnail.first.attributes.should == {:type=>"ActiveFedora::Datastream",
      #                                                     :content_type=>"image/jpeg", 
      #                                                     :prefix=>"THUMB", :mimeType=>"image/jpeg", 
      #                                                     :controlGroup=>"M", :dsid=>"THUMB1", 
      #                                                     :pid=>@test_object2.pid, :dsID=>"THUMB1", 
      #                                                     :name=>"thumbnail", :dsLabel=>"dino.jpg"}
      thumb1 = @test_object2.thumbnail.first
      thumb1.dsid.should == 'THUMB1'
      thumb1.pid.should == @test_object2.pid
      thumb1.dsLabel.should == 'dino.jpg'
      f2.rewind
      @test_object2.thumbnail.first.content.should == f2.read
    end
  end
  
  describe '#create_datastream' do
    it 'should create a datastream object using the type of object supplied in the string (does reflection)' do
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      ds = @test_object.create_datastream("ActiveFedora::Datastream", 'NAME', {:blob=>f})
      ds.class.should == ActiveFedora::Datastream
      ds.dsLabel.should == "minivan.jpg"
      ds.mimeType.should == "image/jpeg"
    end
  end
  
  it 'should provide #is_named_datastream?' do
    @test_object.should respond_to(:is_named_datastream?)
  end
  
  describe '#is_named_datastream?' do
    class MockIsNamedDatastream < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
    end
    
    it 'should return true if a named datastream exists in model' do
      @test_object2 = MockIsNamedDatastream.new
      @test_object2.is_named_datastream?("thumbnail").should == true
      @test_object2.is_named_datastream?("thumb").should == false
    end
  end
  
  it 'should provide #named_datastreams' do
    @test_object.should respond_to(:named_datastreams)
  end
  
  describe '#named_datastreams' do
    class MockNamedDatastreams < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
      has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E' 
    end
    
    it 'should return a hash of datastream names to arrays of datastreams' do
      @test_object2 = MockNamedDatastreams.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg" ))
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stubs(:content_type).returns("image/jpeg")
      f2.stubs(:original_filename).returns("dino.jpg")
      @test_object2.thumbnail_file_append(f)
      @test_object2.high_file_append(f2)
      @test_object2.external_append({:dsLocation=>"http://myresource.com"})
      datastreams = @test_object2.named_datastreams
      datastreams.keys.include?("thumbnail").should == true
      datastreams.keys.include?("external").should == true
      datastreams.keys.include?("high").should == true
      datastreams.keys.size.should == 3
      datastreams["thumbnail"].size.should == 1
      datastreams["thumbnail"].first.dsid.should == 'THUMB1'
      datastreams["thumbnail"].first.dsLabel.should == 'minivan.jpg'
      datastreams["thumbnail"].first.controlGroup.should == "M"
      f.rewind
      datastreams["thumbnail"].first.content.should == f.read

      datastreams["external"].size.should == 1
      datastreams["external"].first.dsid.should == "EXTERNAL1"
      datastreams["external"].first.dsLocation.should == "http://myresource.com"
      datastreams["external"].first.controlGroup.should == "E"
      datastreams["external"].first.content.should == "" 

      datastreams["high"].size.should == 1
      datastreams["high"].first.dsLabel.should == 'dino.jpg'
      datastreams["high"].first.controlGroup.should == "M"
      datastreams["high"].first.dsid.should == "HIGH1"
      f2.rewind
      datastreams["high"].first.content.should == f2.read
    end
  end
  
  
  it 'should provide #named_datastreams_ids' do
    @test_object.should respond_to(:named_datastreams_ids)
  end
  
  describe '#named_datastreams_ids' do
    class MockNamedDatastreamsIds < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
      has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E' 
    end
    
    it 'should provide a hash of datastreams names to array of datastream ids' do
      @test_object2 = MockNamedDatastreamsIds.new
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg" ))
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stubs(:content_type).returns("image/jpeg")
      f2.stubs(:original_filename).returns("dino.jpg")
      @test_object2.thumbnail_file_append(f)
      @test_object2.high_file_append(f2)
      @test_object2.external_append({:dsLocation=>"http://myresource.com"})
      @test_object2.named_datastreams_ids.should == {"thumbnail"=>["THUMB1"],"high"=>["HIGH1"],"external"=>["EXTERNAL1"]}
    end
  end
  
  #
  # Class level methods
  #
  describe '#named_datastreams_desc' do
      
    class MockNamedDatastreamsDesc < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
    end
    
    it 'should intialize a value to an empty hash and then not modify afterward' do
      @test_object.named_datastreams_desc.should == {}
      @test_object2 = MockNamedDatastreamsDesc.new
      @test_object2.named_datastreams_desc.should == {"thumbnail"=>{:name=>"thumbnail",:prefix => "THUMB", 
                                                                    :type=>"ActiveFedora::Datastream", :mimeType=>"image/jpeg", 
                                                                    :controlGroup=>'M'}}
    end
  end
    
  describe '#create_named_datastream_finders' do
    class MockCreateNamedDatastreamFinder < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"high", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M' 
    end
    
    it 'should create helper methods to get named datastreams or dsids' do
      @test_object2 = MockCreateNamedDatastreamFinder.new
      @test_object2.should respond_to(:thumbnail)
      @test_object2.should respond_to(:thumbnail_ids)  
      @test_object2.should respond_to(:high)
      @test_object2.should respond_to(:high_ids)
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f2 = File.new(File.join( File.dirname(__FILE__), "../fixtures/dino.jpg" ))
      f2.stubs(:original_filename).returns("dino.jpg")
      f.stubs(:content_type).returns("image/jpeg")
      @test_object2.add_named_datastream("thumbnail",{:content_type=>"image/jpeg",:blob=>f, :label=>"testDS"})
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      @test_object2.add_named_datastream("high",{:content_type=>"image/jpeg",:blob=>f2})
      t2_thumb1 = @test_object2.thumbnail.first
      t2_thumb1.mimeType.should == "image/jpeg"
      t2_thumb1.controlGroup.should == "M"
      t2_thumb1.dsLabel.should == "testDS"
      t2_thumb1.pid.should == @test_object2.pid 
      t2_thumb1.dsid.should == "THUMB1"
      # :type=>"ActiveFedora::Datastream", 
      # :prefix=>"THUMB", :content_type=>"image/jpeg", :dsid=>"THUMB1", :dsID=>"THUMB1", 
      # :pid=>@test_object2.pid, :mimeType=>"image/jpeg", :controlGroup=>"M", :dsLabel=>"testDS", :name=>"thumbnail", :label=>"testDS"}
      @test_object2.thumbnail_ids.should == ["THUMB1"]
      @test_object2.high_ids.include?("HIGH1") == true
      @test_object2.high_ids.include?("HIGH2") == true
      @test_object2.high_ids.size.should == 2
      #just check returning datastream object at this point
      @test_object2.high.first.class.should == ActiveFedora::Datastream
    end
  end
    
  describe '#create_named_datastream_update_methods' do
    class MockCreateNamedDatastreamUpdateMethods < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"EAD", :type=>ActiveFedora::Datastream, :mimeType=>"application/xml", :controlGroup=>'M' 
      has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E' 
    end
    
    it 'should create append method for each has_datastream entry' do
      @test_object2 = MockCreateNamedDatastreamUpdateMethods.new
      @test_object3 = MockCreateNamedDatastreamUpdateMethods.new
      @test_object2.should respond_to(:thumbnail_append)
      @test_object2.should respond_to(:ead_append)
      f = File.new(File.join( File.dirname(__FILE__), "../fixtures/minivan.jpg"))
      f.stubs(:content_type).returns("image/jpeg")
      f.stubs(:original_filename).returns("minivan.jpg")
      @test_object2.thumbnail_file_append(f)
      t2_thumb1 = @test_object2.thumbnail.first
      t2_thumb1.mimeType.should == "image/jpeg"
      t2_thumb1.dsLabel.should == "minivan.jpg"
      t2_thumb1.pid.should == @test_object2.pid 
      t2_thumb1.dsid.should == "THUMB1"
      @test_object3.thumbnail_append({:file=>f})
      t3_thumb1 = @test_object3.thumbnail.first
      t3_thumb1.mimeType.should == "image/jpeg"
      t3_thumb1.dsLabel.should == "minivan.jpg"
      t3_thumb1.pid.should == @test_object3.pid 
      t3_thumb1.dsid.should == "THUMB1"
      @test_object3.external_append({:dsLocation=>"http://myresource.com"})
      t3_external1 = @test_object3.external.first
      t3_external1.dsLabel.should == "http://myresource.com"
      t3_external1.dsLocation.should == "http://myresource.com"
      t3_external1.pid.should == @test_object3.pid 
      t3_external1.dsid.should == "EXTERNAL1"
      t3_external1.controlGroup == 'E'
    end
  end
    
  describe '#has_datastream' do
    class MockHasDatastream < ActiveFedora::Base
      has_datastream :name=>"thumbnail",:prefix => "THUMB", :type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'
      has_datastream :name=>"EAD", :type=>ActiveFedora::Datastream, :mimeType=>"application/xml", :controlGroup=>'M' 
      has_datastream :name=>"external", :type=>ActiveFedora::Datastream, :controlGroup=>'E'
    end
    
    it 'should cache a definition of named datastream and create helper methods to add/remove/access them' do
      @test_object2 = MockHasDatastream.new
      #prefix should default to name in caps if not specified in has_datastream call
      @test_object2.named_datastreams_desc.should == {"thumbnail"=>{:name=>"thumbnail",:prefix => "THUMB", 
                                                                    :type=>"ActiveFedora::Datastream", :mimeType=>"image/jpeg", 
                                                                    :controlGroup=>'M'},
                                                      "EAD"=>       {:name=>"EAD", :prefix=>"EAD",
                                                                    :type=>"ActiveFedora::Datastream", :mimeType=>"application/xml", 
                                                                    :controlGroup=>'M' },
                                                      "external"=>  {:name=>"external", :prefix=>"EXTERNAL",
                                                                    :type=>"ActiveFedora::Datastream", :controlGroup=>'E' }}
      @test_object2.should respond_to(:thumbnail_append)
      @test_object2.should respond_to(:thumbnail_file_append)
      @test_object2.should respond_to(:thumbnail)
      @test_object2.should respond_to(:thumbnail_ids)
      @test_object2.should respond_to(:ead_append)
      @test_object2.should respond_to(:ead_file_append)
      @test_object2.should respond_to(:EAD)
      @test_object2.should respond_to(:EAD_ids)
      @test_object2.should respond_to(:external)
      @test_object2.should respond_to(:external_ids)
    end
  end
end
