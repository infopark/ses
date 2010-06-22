require 'tempfile'

module Infopark
  module SES
    module Filter

      # Convert the object's body to plain text using Solr's ExtractingRequestHandler
      # Options:
      # <tt>:fallback</tt>:: The value returned if extraction fails (after retry). If unset the exception is thrown
      # <tt>:attempts</tt>:: Overall attempts on errors. Default: <tt>2</tt> (retry once)
      def self.text_via_solr_cell(obj, options = {})
        params = {
          'extractOnly' => true,
          'extractFormat' => 'text',
          'resource.name' => identifier(obj)
        }
        attempts = options[:attempts] || 2
        for attempt in 1..attempts do
          begin
            return RSolr.connect.request('/update/extract', params, obj.body)['']
          rescue StandardError => error
            ActiveRecord::Base.logger.debug "Error filtering obj #{obj.id}, #{obj.path}, attempt #{attempt}: #{error.inspect}"
          end
        end
        return options[:fallback] if options.key?(:fallback)
        raise error
      end

      # convert the object's body to HTML using the Verity input filter (IF)
      def self.html_via_verity(obj)
        in_file = Tempfile.new("IF.in.#{identifier(obj)}.", "#{Rails.root}/tmp")
        out_file = Tempfile.new("IF.out.#{identifier(obj)}.", "#{Rails.root}/tmp")
        in_file.syswrite obj.body

        cmd = "#{@@if_options[:bin_path]} #{@@if_options[:timeout_seconds]} #{in_file.path} " +
            "#{out_file.path} #{@@if_options[:cfg_path]}"
        system cmd or raise cmd

        out_file.reopen(out_file.path, 'r')
        out_file.read
      end

      private

      def self.verity_input_filter=(options)
        @@if_options = options
      end

      def self.identifier(obj)
        "#{obj.id}.#{obj.file_extension}"
      end

    end
  end
end
