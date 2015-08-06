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
    obj = double()
    allow(obj).to receive(:body).and_return(@pdf_body)
    allow(obj).to receive(:id).and_return(2001)
    allow(obj).to receive(:mime_type).and_return('application/pdf')
    allow(obj).to receive(:file_extension).and_return('pdf')
    allow(obj).to receive(:path).and_return('/testpdf')
    expect( Infopark::SES::Filter::text_via_solr_cell(obj) ).to include "The PDF's Text"
  end

end

describe "Filtering via verity " do

  before(:all) do
    pdf = Prawn::Document.new
    pdf.text "The PDF's Text"
    @pdf_body = pdf.render
  end

  after(:all) do
  end

  it "should convert a PDF document's body to html" do
    obj = double()
    allow(obj).to receive(:body).and_return(@pdf_body)
    allow(obj).to receive(:id).and_return(2001)
    allow(obj).to receive(:mime_type).and_return('application/pdf')
    allow(obj).to receive(:file_extension).and_return('pdf')
    allow(obj).to receive(:path).and_return('/testpdf')
    content = Infopark::SES::Filter::html_via_verity(obj).to_s
    expect( content ).to include "The PDF&#39;s Text"
    expect( content ). to include "<!DOCTYPE HTML"
  end

end
