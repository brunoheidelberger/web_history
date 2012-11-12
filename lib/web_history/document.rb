require 'net/https'
require 'web_history/helpers'
require 'web_history/nokogiri_ext'
require 'web_history/settings'

module WebHistory
  class Document
    attr_reader :url
    attr_reader :approved_digest
    attr_reader :approved_time
    attr_reader :versions

    def initialize(url = nil, options = {})
      @url = url

      options = Helpers::symbolize_keys(options)
      @settings = options[:settings].is_a?(Settings) ? options[:settings] : Settings.new(options[:settings] || {})

      @approved_digest = options[:approved_digest]
      @approved_time = options[:approved_time]

      @versions = []
      versions = options[:versions] || []
      versions.each { |version| @versions << Helpers::symbolize_keys(version) }

      @html_document = nil
    end

    def to_hash
      {
        'url' => @url,
        'approved_digest' => @approved_digest,
        'approved_time' => @approved_time,
        'versions' => @versions.collect { |version| Helpers::stringify_keys(version) }
      }
    end

    def update(options = {})
      fetch

      normalized_digest = @html_document.root.accumulated_digest
      latest_digest = @versions.empty? ? nil : @versions.first[:digest]

      if normalized_digest != latest_digest
        @versions.unshift({
          :digest => normalized_digest,
          :time => Time.now
        })

        File.open("#{@settings.document_path}/#{normalized_digest}.html", 'w') { |file| dump(file) }
      end
    end

    def updated?
      return false if @versions.empty?

      @approved_digest != @versions.first[:digest]
    end

    def approve
      return if @versions.empty?

      @approved_digest = @versions.first[:digest]
      @approved_time = Time.now
    end

    private

    def fetch()
      uri = URI.parse(@url)

      raise 'No scheme specified in URL.' if uri.scheme.nil?

      http = Net::HTTP.new(uri.host, uri.port)
      if uri.port == URI::HTTPS::DEFAULT_PORT
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      begin
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
      rescue Errno::ECONNREFUSED
        raise "Unable to fetch page from URL."
      end

      raise "Invalid HTTP response code." unless response.kind_of?(Net::HTTPOK)

      charset = nil
      case response.type_params['charset']
      when 'iso-8859-1'
        charset = 'windows-1252'
      when 'utf-8'
        charset = 'utf-8'
      else
        raise "Unknown charset."
      end
      body = charset == 'utf-8' ? response.body : response.body.encode('utf-8', charset)

      @html_document = Nokogiri::HTML(body)
      @html_document.meta_encoding = 'utf-8'

      #puts @html_document.errors
      
      normalize

      digest

      nil
    end

    def traverse(&block)
      return if @html_document.nil?

      Nokogiri::XML::NodeHelpers.traverse(@html_document.root, 0, &block)
    end

    def normalize
      traverse { |node, type| Nokogiri::XML::NodeHelpers.normalize(node) if type == :before }
    end

    def digest
      mode =
        case @settings.digest_mode
        when 'all'
          Nokogiri::XML::NodeHelpers::DigestModes::ALL
        when 'no_attributes'
          Nokogiri::XML::NodeHelpers::DigestModes::NO_ATTRIBUTES
        else
          raise "Invalid digest mode."
        end

      traverse { |node, type| Nokogiri::XML::NodeHelpers.digest(node, mode) if type == :after }
    end

    def dump(io = STDIN)
      traverse do |node, type, level|
        str = Nokogiri::XML::NodeHelpers.to_str(node, type)
        io.puts "#{'  ' * level}#{str}" unless str.nil?
      end
    end
  end
end

