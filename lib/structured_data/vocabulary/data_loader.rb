# frozen_string_literal: true

require "json"
require "pathname"

module StructuredData
  class Vocabulary
    module DataLoader
      DEFAULT_DATA_PATH = File.expand_path("../../../data/schema_org_v30.json", __dir__)

      def self.load(source)
        case source
        when nil
          JSON.parse(File.read(DEFAULT_DATA_PATH))
        when Hash
          source
        when String, Pathname
          JSON.parse(File.read(source.to_s))
        else
          raise ArgumentError, "Invalid vocabulary source: #{source.inspect}"
        end
      end
    end
  end
end
