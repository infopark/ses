require File.dirname(__FILE__) + '/../spec_helper'
require 'prawn'
require 'base64'

describe "Solr multicore integration" do

  def hit_count(q, core)
    @solr_client[core].get("select", :params => {:q => q})['response']['numFound']
  end

  before(:all) do
    @cm = TestCM.new
    @cm.setup
    @solr = TestSolrMulticore.new
    @solr.setup
  end

  before do
    @solr_client = [RSolr.connect(:url => 'http://127.0.0.1:8983/solr/core0'),
        RSolr.connect(:url => 'http://127.0.0.1:8983/solr/core1')]
    Infopark::SES::Indexer.collections = {
      :c0 => 'http://127.0.0.1:8983/solr/core0',
      :c1 => 'http://127.0.0.1:8983/solr/core1'
    }

    Infopark::SES::Indexer.collection_selection do |obj|
      case obj.name
        when 'core_0' then :c0
        when 'core_1' then :c1
        when 'no_core' then nil
        else [:c0, :c1]
      end
    end
  end

  after(:all) do
    @solr.teardown
    @cm.teardown
  end


  it "should find a Document in the selected collection(s)" do
    @cm.tcl "
      obj root create name core_x objClass Document
      obj withPath /core_x editedContent set blob multicoretest1
      obj withPath /core_x release
    "
    @cm.tcl "
      obj root create name core_0 objClass Document
      obj withPath /core_0 editedContent set blob multicoretest2
      obj withPath /core_0 release
    "
    @cm.tcl "
      obj root create name core_1 objClass Document
      obj withPath /core_1 editedContent set blob multicoretest3
      obj withPath /core_1 release
    "
    Infopark::SES::Indexer.perform( Obj.where(:path => "/core_x").all.first.id )
    Infopark::SES::Indexer.perform( Obj.where(:path => "/core_0").all.first.id )
    Infopark::SES::Indexer.perform( Obj.where(:path => "/core_1").all.first.id )

    expect( lambda { hit_count('body:multicoretest1', 0) } ).to eventually_be(1)
    expect( lambda { hit_count('body:multicoretest1', 1) } ).to eventually_be(1)

    expect( lambda { hit_count('body:multicoretest2', 0) } ).to eventually_be(1)
    expect( lambda { hit_count('body:multicoretest2', 1) } ).to eventually_be(0)

    expect( lambda { hit_count('body:multicoretest3', 0) } ).to eventually_be(0)
    expect( lambda { hit_count('body:multicoretest3', 1) } ).to eventually_be(1)
  end


  it "should be able to index into no collection" do
    @cm.tcl "
      obj root create name nocoretest objClass Document
      obj withPath /nocoretest editedContent set blob nocoretest1
      obj withPath /nocoretest release
    "
    @cm.tcl "
      obj root create name no_core objClass Document
      obj withPath /no_core editedContent set blob nocoretest2
      obj withPath /no_core release
    "
    Infopark::SES::Indexer.perform( Obj.where(:path => "/nocoretest").all.first.id )
    Infopark::SES::Indexer.perform( Obj.where(:path => "/no_core").all.first.id )

    expect( lambda { hit_count('body:nocoretest1', 0) } ).to eventually_be(1)
    expect( lambda { hit_count('body:nocoretest1', 1) } ).to eventually_be(1)

    expect( lambda { hit_count('body:nocoretest2', 0) } ).to eventually_be(0)
    expect( lambda { hit_count('body:nocoretest2', 1) } ).to eventually_be(0)
  end

end
