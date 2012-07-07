require 'web_history/folder'

module WebHistory
  class Portfolio
    attr_reader :filename
    attr_reader :folders
    attr_reader :settings

    def initialize(filename = nil, options = {})
      @filename = filename

      options = Helpers::symbolize_keys(options)
      @settings = options[:settings].is_a?(Settings) ? options[:settings] : Settings.new(options[:settings] || {})

      @folders = []
      folders = options[:folders] || []
      folders.each do |folder|
        folder = Helpers::symbolize_keys(folder)
        folder[:settings] = @settings
        @folders << Folder.new(folder.delete(:name), folder)
      end
    end

    def to_hash
      {
        'portfolio' => {
          'settings' => @settings.to_hash,
          'folders' => @folders.collect { |folder| folder.to_hash }
        }
      }
    end

    def self.load(filename)
      portfolio = YAML.load(File.open(filename))

      new(filename, portfolio['portfolio'])
    end

    def save(filename = nil)
      @filename = filename || @filename

      File.open(@filename, 'w') do |file|
        file.write(to_hash.to_yaml)
      end
    end

    def add_folder(name, options = {})
      return if @folders.any? { |folder| folder.name == name }

      options[:settings] = @settings

      folder = Folder.new(name, options)
      @folders << folder

      folder
    end

    def remove_folder(name)
      @folders.delete_if { |folder| folder.name == name }
    end

    def update(options = {})
      @folders.each { |folder| folder.update(options) }
    end

    def updated?
      return false if @folders.empty?

      @folders.any? { |folder| folder.updated? }
    end
  end
end

