# frozen_string_literal: true

require_relative "diagnostic"

module StructuredData
  class Validator
    class Context
      attr_reader :mode, :diagnostics

      def initialize(mode, diagnostics)
        @mode = mode
        @diagnostics = diagnostics
      end

      def severity
        mode == :strict ? :error : :warning
      end

      def add(code:, severity:, path:, message:, suggestion: nil)
        diagnostics << Diagnostic.new(
          code: code,
          severity: severity,
          path: path,
          message: message,
          suggestion: suggestion
        )
      end
    end
  end
end
