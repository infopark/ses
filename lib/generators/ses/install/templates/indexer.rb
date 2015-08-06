Infopark::SES::Indexer.index_fields do |obj|
  if obj.released? && !obj.suppress_export? && !obj.image?
    if obj.generic?
      plain_body = Infopark::SES::Filter::text_via_solr_cell(obj,{:fallback => ''})
    end
    {
      :id => obj.id,
      :name => obj.name,
      :path => obj.path,
      :body => plain_body || obj.body,
      :valid_from => obj.valid_from.utc.iso8601,
      :valid_until => (obj.valid_until && obj.valid_until.utc.iso8601),
      :title => obj.title,
    }
  end
end

# Single configuration:

Infopark::SES::Indexer.collections = {
  "default" => 'http://127.0.0.1:8983/solr/default'
}

# Multicore configuration:

# Infopark::SES::Indexer.collections = {
#   "de" => 'http://127.0.0.1:8983/solr/de',
#   "en" => 'http://127.0.0.1:8983/solr/en',
# }
#
# Infopark::SES::Indexer.collection_selection do |obj|
#   language_path_component = obj.path.split("/", 3)[1]
#   [language_path_component] & %w(de en)
# end

Infopark::SES::Indexer.solr_options = {
  # Provide additional parameters to the solr add request (http://wiki.apache.org/solr/UpdateXmlMessages)
  :add => {},
  # Provide additional parameters to the solr optimize request
  :optimize => {}
}
