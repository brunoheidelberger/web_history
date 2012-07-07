require 'web_history/document'

module WebHistory
  class Folder
    attr_reader :name
    attr_reader :update_time
    attr_reader :update_interval
    attr_reader :documents

    def initialize(name = nil, options = {})
      @name = name

      options = Helpers::symbolize_keys(options)
      @settings = options[:settings].is_a?(Settings) ? options[:settings] : Settings.new(options[:settings] || {})

      @update_time = options[:update_time] || Time.now
      @update_interval = options[:update_interval] || 24 * 60 * 60

      @documents = []
      documents = options[:documents] || []
      documents.each do |document|
        document = Helpers::symbolize_keys(document)
        document[:settings] = @settings
        @documents << Document.new(document.delete(:url), document)
      end
    end

    def to_hash
      {
        'name' => @name,
        'update_time' => @update_time,
        'update_interval' => @update_interval,
        'documents' => @documents.collect { |document| document.to_hash }
      }
    end

    def add_document(url, options = {})
      return if @documents.any? { |document| document.url == url }

      options[:settings] = @settings

      document = Document.new(url, options)
      @documents << document

      document
    end

    def remove_document(url)
      @documents.delete_if { |document| document.url == url }
    end

    def update(options = {})
      return unless (Time.now >= @update_time) || options[:force]

      @documents.each { |document| document.update(options) }

      @update_time = Time.now + @update_interval
    end

    def updated?
      return false if @documents.empty?

      @documents.any? { |document| document.updated? }
    end
  end
end

