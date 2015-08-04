Infopark::SES::Filter.verity_input_filter = {
  :bin_path => Dir.glob("#{ENV['HOME']}/*/instance/default/bin/IF").first,
  :cfg_path => Dir.glob("#{ENV['HOME']}/*/instance/default/config/IF.cfg.indexing").first,
  :timeout_seconds => 30
}

# Extract text with Solr Content Extraction Library (Solr Cell)
# http://wiki.apache.org/solr/ExtractingRequestHandler
Infopark::SES::Filter.solr_cell_filter = {
  :solr_core_url => "http://127.0.0.1:8983/solr/default",
  :attempts => 2,
  :fallback => ''
}
