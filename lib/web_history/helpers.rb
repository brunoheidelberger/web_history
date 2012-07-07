module WebHistory
  module Helpers
    def self.stringify_keys(hash)
      hash.inject({}) do |options, (key, value)|
        options[key.to_s] = value
        options
      end
    end

    def self.symbolize_keys(hash)
      hash.inject({}) do |options, (key, value)|
        options[key.to_sym] = value
        options
      end
    end
  end
end

