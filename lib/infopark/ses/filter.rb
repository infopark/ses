require 'tempfile'

module Infopark
  module SES
    module Filter

      # Convert the object's body to plain text using Solr's ExtractingRequestHandler
      # Options:
      # <tt>:fallback</tt>:: The value returned if extraction fails (after retry). If unset the exception is thrown
      # <tt>:attempts</tt>:: Overall attempts on errors. Default: <tt>2</tt> (retry once)
      # <tt>:solr_core_url</tt>:: Url of the core whcih should be used for extraction
      def self.text_via_solr_cell(obj, options = {})
        data = obj.body
        mime_type = obj.mime_type
        options.reverse_merge!(@@solr_options)
        attempts = options[:attempts] || 2
        if options[:solr_core_url]
          extractUrl = options[:solr_core_url] + "/update/extract"
        else
          extractUrl = "http://127.0.0.1:8983/solr/default/update/extract"
        end
        for attempt in 1..attempts do
          begin
            return RSolr.connect.post( extractUrl,
                :params => {
                  'extractOnly' => true,
                  'extractFormat' => 'text',
                  'resource.name' => identifier(obj)
                },
                :data => data,
                :headers => {
                  "Content-type" => mime_type,
                }
              )['']
          rescue StandardError => error
            msg = "Error filtering obj #{obj.id}, #{obj.path}, attempt #{attempt}: #{error.inspect}"
            ActiveRecord::Base.logger.debug msg 
            puts "[#{Time.new.strftime('%Y-%m-%d %H:%M:%S')}] Error #{msg}"
          end
        end
        return options[:fallback] if options.key?(:fallback)
        raise error
      end

      @@solr_options = {
        :solr_core_url => "http://127.0.0.1:8983/solr/default",
        :attempts => 2,
        :fallback => ''
      }

      def self.solr_cell_filter=(options)
        @@solr_options = options
      end

      # convert the object's body to HTML using the Verity input filter (IF)
      def self.html_via_verity(obj)
        in_file = Tempfile.new("IF.in.#{identifier(obj)}.", "#{::Rails.root}/tmp")
        out_file = Tempfile.new("IF.out.#{identifier(obj)}.", "#{::Rails.root}/tmp")
        in_file.syswrite obj.body

        cmd = "#{@@if_options[:bin_path]} #{@@if_options[:timeout_seconds]} #{in_file.path} " +
            "#{out_file.path} #{@@if_options[:cfg_path]}"
        system cmd or raise cmd

        out_file.reopen(out_file.path, 'r')
        out_file.read
      end

      def self.verity_input_filter=(options)
        @@if_options = options
      end

      def self.identifier(obj)
        "#{obj.id}.#{obj.file_extension}"
      end

    end
  end
end
