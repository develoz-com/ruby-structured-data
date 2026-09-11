# frozen_string_literal: true

module StructuredData
  class Error < StandardError; end

  class ValidationError < Error
    attr_reader :result

    def initialize(result_or_message = nil)
      if result_or_message.respond_to?(:errors)
        @result = result_or_message
        errors_str = @result.errors.map { |e| "#{e.path}: #{e.message}" }.join("; ")
        super("Validation failed: #{errors_str}")
      else
        super(result_or_message || "Validation failed")
      end
    end
  end
end
