Elasticsearch::Model.client = Elasticsearch::Client.new url: ENV['ELASTICSEARCH_URL'] || "http://localhost:9200/"

unless Profile.__elasticsearch__.index_exists?
  Profile.__elasticsearch__.create_index! force: true
  Profile.import
end