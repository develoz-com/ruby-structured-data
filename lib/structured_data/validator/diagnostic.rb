# frozen_string_literal: true

module StructuredData
  class Validator
    class Diagnostic
      attr_reader :code, :severity, :path, :message, :suggestion

      def initialize(code:, severity:, path:, message:, suggestion: nil)
        @code = code
        @severity = severity
        @path = path
        @message = message
        @suggestion = suggestion
      end

      def error?
        severity == :error
      end

      def warning?
        severity == :warning
      end

      def to_h
        {
          code: code,
          severity: severity,
          path: path,
          message: message,
          suggestion: suggestion
        }
      end

      def ==(other)
        other.is_a?(self.class) && to_h == other.to_h
      end
      alias eql? ==

      def hash
        [self.class, to_h].hash
      end
    end
  end
  Diagnostic = Validator::Diagnostic
end
