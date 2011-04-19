module CCML
  module Tag

    class Base

      attr_reader :url
      attr_reader :host
      attr_reader :resource
      attr_reader :path
      attr_reader :query_string
      attr_reader :segments
      attr_reader :fields

      attr_reader :opts

      define_method(:qs) { return @query_string }
      define_method(:http?) { return @http }
      define_method(:https?) { return @https }

      def initialize(opts, url = nil)
        if opts.is_a?(Hash)
          @opts = opts
        else
          @opts = {}
        end
        parse_url(url)
        update_opts_from_url_segments
        update_opts_from_url_fields
      end

      def index
        raise CCML::Error::NotImplementedError, "You must override the index method in all #{self.class} subclasses."
      end

      private

      def parse_url(url)

        @segments = []
        @fields = {}

        # parse the url or die
        match = /^(?<protocol>http[s]?):\/\/(?<host>(\w|[^\?\/])+)(?<resource>.*)$/i.match(url)
        return if match.nil?

        # get the main pieces
        @http = ( match[:protocol] == 'http' )
        @https = ! @http
        @host = match[:host]
        @resource = match[:resource]

        # get the path and query string
        match = /(?<path>^\/[^\?]*)?\/?(\?(?<qs>\S*$))?/.match(@resource)
        @path = ( match[:path] =~ /^\/$/ ? nil : match[:path] )
        @path = @path[0, @path.size-1] if @path =~ /\/$/
        @query_string = match[:qs]

        # parse the path segments
        @segments = @path.split('/') unless @path.blank?
        @segments.shift if @segments[0].blank?

        # parse the query string fields
        unless @query_string.blank?
          matches = @query_string.scan(/(?<field>[^=]+)=(?<value>[^&]+)\&?/)
          matches.each do |match|
            @fields[match.first.to_sym] = match.last
          end
        end

      end

      def update_opts_from_url_segments
        @opts.each do |key, value|
          match = /^segment_(?<index>\d+)$/i.match(value)
          if match
            @opts[key] = @segments[match[:index].to_i]
          elsif value =~ /^last_segment$/i
            @opts[key] = @segments.last
          end
        end
      end

      def update_opts_from_url_fields
        @opts.each do |key, value|
          match = /^field_(?<index>\w+)$/i.match(value)
          if match
            @opts[key] = @fields[match[:index].to_sym]
          elsif value =~ /^query_string$/i
            @opts[key] = @query_string
          end
        end
      end

    end

  end
end