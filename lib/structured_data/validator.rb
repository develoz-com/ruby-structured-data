# frozen_string_literal: true

require_relative "validator/diagnostic"
require_relative "validator/result"
require_relative "validator/context"
require_relative "validator/range_checker"
require_relative "validator/node_validator"

module StructuredData
  class Validator
    VALID_MODES = %i[schema_org strict none].freeze

    class << self
      def validate(target, mode: :schema_org, vocabulary: StructuredData::Vocabulary.default)
        new(vocabulary: vocabulary).validate(target, mode: mode)
      end

      def validate!(target, mode: :schema_org, vocabulary: StructuredData::Vocabulary.default)
        new(vocabulary: vocabulary).validate!(target, mode: mode)
      end
    end

    attr_reader :vocabulary, :node_validator

    def initialize(vocabulary: StructuredData::Vocabulary.default)
      @vocabulary = vocabulary
      range_checker = RangeChecker.new(vocabulary)
      @node_validator = NodeValidator.new(vocabulary, range_checker)
    end

    def validate(target, mode: :schema_org)
      validate_mode!(mode)
      return Result.new if mode == :none

      diagnostics = []
      validate_target(target, Context.new(mode, diagnostics))
      Result.new(diagnostics)
    end

    def validate!(target, mode: :schema_org)
      result = validate(target, mode: mode)
      raise ValidationError, result unless result.valid?

      result
    end

    private

    def validate_mode!(mode)
      return if VALID_MODES.include?(mode)

      raise ArgumentError, "Invalid validation mode: #{mode.inspect}"
    end

    def validate_target(target, context)
      case target
      when Document
        validate_document(target, context)
      when Node
        node_validator.validate(target, "$", context)
      else
        raise ArgumentError, "Target must be a StructuredData::Node or StructuredData::Document"
      end
    end

    def validate_document(document, context)
      if document.nodes.size == 1 && !document.graph?
        node_validator.validate(document.nodes.first, "$", context)
      else
        document.nodes.each_with_index do |node, idx|
          node_validator.validate(node, "$.@graph[#{idx}]", context)
        end
      end
    end
  end
end
