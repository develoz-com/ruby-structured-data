# frozen_string_literal: true

module StructuredData
  class Configuration
    DEFAULT_VALIDATION_MODE = :schema_org
    DEFAULT_PRETTY = false

    attr_accessor :validation_mode, :pretty

    def initialize
      reset!
    end

    def reset!
      @validation_mode = DEFAULT_VALIDATION_MODE
      @pretty = DEFAULT_PRETTY
    end
  end
end
