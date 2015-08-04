module Infopark
  module SES

    class Indexer
      attr_accessor :indexed_docs

      def self.queue
        "index_#{RailsConnector::InfoparkBase.instance_name}"
      end

      # The callback that decides which fields are to be indexed. See
      # config/initializers/indexer.rb. It may return nil to indicate that the
      # object should not be indexed.
      def self.index_fields(&block)
        @@index_fields_callback = block
      end

      # A hash of keys and Solr URLs to allow indexing into different collections
      def self.collections=(hash)
        @@collections = hash
      end

      # A hash of options to pass to Solr calls. For example:
      #
      # {optimize: { expungeDeletes: true, waitSearcher: false } }
      def self.solr_options=(hash)
        @@solr_options = hash
      end

      # The callback that decides which collections will receive an indexing request.
      # See config/initializers/indexer.rb. It may return a single key or an array of keys.
      def self.collection_selection(&block)
        @@collection_selection_callback = block
      end

      def self.perform(obj_id)
        log :info, "New job: index obj #{obj_id}"
        new.index(obj_id)
      rescue ActiveRecord::StatementInvalid => e
        log :error, "[#{e.class}] #{e}"
        unless ActiveRecord::Base.connected? && ActiveRecord::Base.connection.active?
          log :warning, "Detected lost connection. Trying to reconnect..."
          ActiveRecord::Base.connection_handler.clear_all_connections!
          db_yml = YAML::load(File.read(::Rails.root + 'config/database.yml'))
          ActiveRecord::Base.establish_connection(db_yml['cms'])
          retry
        end
      end

      def reindex_all
        rsolr_connect.each_value do |solr_client|
          solr_client.delete_by_query('*:*')
        end
        Obj.find_each do |obj|
          Resque.enqueue(Infopark::SES::Indexer, obj.id)
        end
      end

      def initialize
      end

      def index(obj_id)
        solr_clients = rsolr_connect
        obj = Obj.find_by_obj_id(obj_id)
        fields = obj && fields_for(obj)
        collections = obj && collections_for(obj)

        solr_clients.each do |collection, solr_client|
          if fields && collections.include?(collection)
            log :info, "Indexing obj #{obj.id} (#{obj.path}) into collection #{collection}"
            solr_client.add(fields, add_attributes: add_options)
          else
            log :info, "Deleting obj #{obj_id} from collection #{collection}"
            solr_client.delete_by_id(obj_id)
          end
        end
        self.indexed_docs += 1

        optimize if trigger_optimize?
      end

      def indexed_docs
        @indexed_docs || 0
      end

      def optimize
        solr_clients = rsolr_connect

        solr_clients.each do |collection, solr_client|
          log :info, "optimizing collection #{collection}"
          solr_client.optimize(optimize_attributes: optimize_options)
        end
      end

      private

      @@solr_options = {}
      @@collections = {:default => 'http://127.0.0.1:8983/solr/default'}
      @@collection_selection_callback = lambda {|obj| :default}

      def rsolr_connect
        @@collections.merge(@@collections) do |k, url|
          RSolr.connect(:url => url)
        end
      end

      def fields_for(obj)
        @@index_fields_callback.call(obj)
      end

      def collections_for(obj)
        Array(@@collection_selection_callback.call(obj))
      end

      def optimize_options
        @@solr_options[:optimize] || {}
      end

      def add_options
        @@solr_options[:add] || {}
      end

      def trigger_optimize?
        self.indexed_docs > 2
      end

      def log(severity, msg)
        self.class.log(severity, msg)
      end

      def optimize_options
        @@solr_options[:optimize] || {}
      end

      def add_options
        @@solr_options[:add] || {}
      end

      def trigger_optimize?
        self.indexed_docs > 2
      end

      def self.log(severity, msg)
        puts "[#{Time.new.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.to_s.upcase} #{msg}"
      end
    end
  end
end
