require File.dirname(__FILE__) + '/../spec_helper'
require 'prawn'

describe "Filtering via Solr Cell" do

  before(:all) do
    @solr = TestSolr.new
    @solr.setup

    pdf = Prawn::Document.new
    pdf.text "The PDF's Text"
    @pdf_body = pdf.render
  end

  after(:all) do
    @solr.teardown
  end

  it "should convert a PDF document's body to text" do
    obj = mock("obj", 
      { 
        :body => @pdf_body, 
        :id => 2001, 
        :mime_type => 'application/pdf',
        :file_extension => 'pdf'
      }
    );
    Infopark::SES::Filter::text_via_solr_cell(obj,{}).should include "The PDF's Text"
  end

end
