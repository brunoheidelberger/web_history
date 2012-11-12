module WebHistory
  class Settings
    attr_reader :portfolio_path
    attr_writer :document_path
    attr_accessor :digest_mode

    def initialize(options = {})
      options = Helpers::symbolize_keys(options)

      @portfolio_path = ''
      @document_path = options[:document_path] || '.'
      @digest_mode = options[:digest_mode] || 'all'
    end
    
    def to_hash
      {
        'document_path' => @document_path,
        'digest_mode' => @digest_mode
      }
    end

    def portfolio_path=(path)
      @portfolio_path = path.nil? ? '' : path
      @portfolio_path << '/' unless @portfolio_path.end_with?('/') || @portfolio_path.empty?
    end

    def document_path
      "#{@portfolio_path}#{@document_path}"
    end
  end
end

