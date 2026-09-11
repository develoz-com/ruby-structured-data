# frozen_string_literal: true

module StructuredData
  class Validator
    class RangeChecker
      DATA_TYPES = %w[Text URL Date DateTime Time XPathType CssSelectorType PronounceableText DataType].freeze
      NUMBER_TYPES = %w[Number Integer Float DataType].freeze
      BOOLEAN_TYPES = %w[Boolean DataType].freeze
      DATE_TIME_TYPES = %w[Date DateTime Time Text DataType].freeze
      URL_TEXT_TYPES = %w[URL Text DataType].freeze
      ENUM_FALLBACK_TYPES = %w[Text URL DataType Enumeration].freeze

      attr_reader :vocabulary

      def initialize(vocabulary)
        @vocabulary = vocabulary
      end

      def matches?(val, ranges)
        return true if ranges.empty?

        case val
        when Node
          node_matches?(val, ranges)
        when Reference
          true
        when Enum
          enum_matches?(val, ranges)
        when Values::Url, URI::Generic, Values::Text
          ranges.intersect?(URL_TEXT_TYPES)
        else
          primitive_matches?(val, ranges)
        end
      end

      private

      def node_matches?(val, ranges)
        return true if ranges.include?(val.type) || ranges.include?("Thing")

        vocabulary.ancestors(val.type).intersect?(ranges)
      end

      def enum_matches?(val, ranges)
        if val.type
          return false unless enum_type_matches?(val, ranges)
          return false if vocabulary.enum_type?(val.type) && !vocabulary.enum_member?(val.type, val.name)

          return true
        end

        return true if ranges.intersect?(ENUM_FALLBACK_TYPES)

        ranges.any? { |range| vocabulary.enum_member?(range, val.name) }
      end

      def enum_type_matches?(val, ranges)
        ranges.include?(val.type) || vocabulary.ancestors(val.type).intersect?(ranges)
      end

      def primitive_matches?(val, ranges)
        case val
        when String
          string_matches?(val, ranges)
        when Integer, Float, Numeric
          ranges.intersect?(NUMBER_TYPES)
        when TrueClass, FalseClass
          ranges.intersect?(BOOLEAN_TYPES)
        when Date, Time
          ranges.intersect?(DATE_TIME_TYPES)
        else
          false
        end
      end

      def string_matches?(val, ranges)
        return true if ranges.intersect?(DATA_TYPES)

        ranges.any? { |range| vocabulary.enum_member?(range, val) }
      end
    end
  end
end
