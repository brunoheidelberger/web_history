module WebHistory
  class Settings
    attr_reader :document_path

    def initialize(options = {})
      @document_path = options[:document_path] || '.'
    end
    
    def to_hash
      {
        'document_path' => @document_path
      }
    end
  end
end

