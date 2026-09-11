# frozen_string_literal: true

require_relative "diagnostic"

module StructuredData
  class Validator
    class Result
      attr_reader :diagnostics

      def initialize(diagnostics = [])
        @diagnostics = diagnostics.dup.freeze
      end

      def valid?
        errors.empty?
      end

      def errors
        diagnostics.select(&:error?)
      end

      def warnings
        diagnostics.select(&:warning?)
      end

      def ==(other)
        other.is_a?(self.class) && diagnostics == other.diagnostics
      end
      alias eql? ==

      def hash
        [self.class, diagnostics].hash
      end
    end
  end
  ValidationResult = Validator::Result
end
