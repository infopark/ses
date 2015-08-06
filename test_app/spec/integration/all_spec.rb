require File.dirname(__FILE__) + '/../spec_helper'
require 'prawn'
require 'base64'

describe "Resque + Solr integration" do

  def hit_count(q)
    @solr_client.get("select", :params => {
      :q => q,
      :fq => [
      "NOT valid_from:[NOW TO *]",
      "NOT valid_until:[* TO NOW-1SECONDS]"
      ]
    })['response']['numFound']
  end

  before(:all) do
    system "bundle exec rake index:worker:start INTERVAL=1 RAILS_ENV=production"

    @cm = TestCM.new
    @cm.setup

    @solr = TestSolr.new
    @solr.setup

    @solr_client = RSolr.connect(:url => 'http://127.0.0.1:8983/solr/default')
  end

  after(:all) do
    @solr.teardown
    @cm.teardown
    system "bundle exec rake index:worker:stop"
  end


  it "an object should be found under its name" do
    hit_count('name:999').should == 0
    @cm.tcl "
      obj root create name 999 objClass Document
      obj withPath /999 release
    "

    lambda { hit_count('name:999') }.should eventually_be(1)
  end


  it "an object whose path has changed should be found under the new path" do
    hit_count('path:\/misc\/errors\/401').should == 0
    @cm.tcl "obj withPath /global set name misc"

    lambda { hit_count('path:\/misc\/errors\/401') }.should eventually_be(1)
  end


  it "an object which has an HTML body should be found by searching a word of the body" do
    hit_count('body:Boddie').should == 0
    @cm.tcl %!
      obj root edit
      obj root editedContent set blob "Das ist der Boddie des Objekts"
      obj root release
    !

    lambda { hit_count('body:Boddie') }.should eventually_be(1)
  end


  it "an object which has an HTML body should not be found by searching an HTML tag name" do
    @cm.tcl %!
      obj root create name htmlbody objClass Document
      obj withPath /htmlbody editedContent set blob "Das ist der <span>Boddie</span> des Objekts"
      obj withPath /htmlbody release
    !
    lambda { hit_count('name:htmlbody') }.should eventually_be(1)

    hit_count('body:span').should == 0
  end


  it "an object which no longer exists should not be found" do
    @cm.tcl "
      obj root create name tobedel objClass Document
      obj withPath /tobedel release
    "
    lambda { hit_count('name:tobedel') }.should eventually_be(1)
    @cm.tcl "obj withPath /tobedel delete"

    lambda { hit_count('name:tobedel') }.should eventually_be(0)
  end


  it "an object which is not released should not be found" do
    @cm.tcl "
      obj root create name tobeunreleased objClass Document
      obj withPath /tobeunreleased release
    "
    lambda { hit_count('name:tobeunreleased') }.should eventually_be(1)
    @cm.tcl "obj withPath /tobeunreleased unrelease"

    lambda { hit_count('name:tobeunreleased') }.should eventually_be(0)
  end


  it "an object which will be valid in the future should not be found" do
    @cm.tcl "
      obj root create name future objClass Document
      obj withPath /future release
    "
    lambda { hit_count('name:future') }.should eventually_be(1)

    @cm.tcl "
      obj withPath /future edit
      obj withPath /future editedContent set validFrom #{3.days.from_now.to_iso}
      obj withPath /future release
    "

    lambda { hit_count('name:future') }.should eventually_be(0)
  end


  it "an object which was valid in the past should not be found" do
    @cm.tcl "
      obj root create name past objClass Document
      obj withPath /past release
    "
    lambda { hit_count('name:past') }.should eventually_be(1)

    @cm.tcl "
      obj withPath /past edit
      obj withPath /past editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /past editedContent set validUntil #{3.days.ago.to_iso}
      obj withPath /past release
    "

    lambda { hit_count('name:past') }.should eventually_be(0)
  end


  it "an object which is valid since the past and will not become invalid should be found" do
    @cm.tcl "
      obj root create name valid_from_past_and_valid_until_open_end objClass Document
      obj withPath /valid_from_past_and_valid_until_open_end editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /valid_from_past_and_valid_until_open_end release
    "

    lambda { hit_count("name:valid_from_past_and_valid_until_open_end") }.should eventually_be(1)
  end


  it "an object which is valid since the past but will become invalid in the future should be found" do
    @cm.tcl "
      obj root create name valid_from_past_and_valid_until objClass Document
      obj withPath /valid_from_past_and_valid_until editedContent set validFrom #{4.days.ago.to_iso}
      obj withPath /valid_from_past_and_valid_until editedContent set validUntil #{2.days.from_now.to_iso}
      obj withPath /valid_from_past_and_valid_until release
    "

    lambda { hit_count('name:valid_from_past_and_valid_until') }.should eventually_be(1)
  end


  it "should find text within a PDF Document" do
#    pending
    pdf = Prawn::Document.new
    pdf.text 'This is auniquepdfword in a PDF Document'
    blob64 = Base64.encode64(pdf.render)
    @cm.tcl "
      obj root create name pdf objClass Generic
      obj withPath /pdf editedContent set blob.base64 {#{blob64}}
      obj withPath /pdf release
    "

    lambda { hit_count('body:auniquepdfword') }.should eventually_be(1)
  end

end
