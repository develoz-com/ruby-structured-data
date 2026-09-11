# frozen_string_literal: true

require "did_you_mean"

module StructuredData
  class Validator
    class NodeValidator
      attr_reader :vocabulary, :range_checker

      def initialize(vocabulary, range_checker)
        @vocabulary = vocabulary
        @range_checker = range_checker
      end

      def validate(node, path, context)
        validate_node_type(node, path, context)

        node.attributes.each do |prop, value|
          validate_attribute(node, prop, value, path, context)
        end
      end

      private

      def validate_node_type(node, path, context)
        if (replacing = vocabulary.superseded_by(node.type))
          context.add(
            code: :superseded_term, severity: context.severity,
            path: "#{path}.@type", message: "Type '#{node.type}' is superseded by '#{replacing}'",
            suggestion: replacing
          )
        end

        return if vocabulary.type_defined?(node.type) || replacing

        context.add(
          code: :unknown_type, severity: :error,
          path: "#{path}.@type", message: "Unknown type '#{node.type}'",
          suggestion: suggest_type(node.type)
        )
      end

      def validate_attribute(node, prop, value, path, context)
        validate_property_name(node, prop, path, context)
        return unless vocabulary.property_defined?(prop)

        validate_property_domain(node, prop, path, context)
        validate_property_range(prop, value, path, context)
      end

      def validate_property_name(node, prop, path, context)
        if (replacing = vocabulary.superseded_by(prop))
          context.add(
            code: :superseded_term, severity: context.severity,
            path: "#{path}.#{prop}", message: "Property '#{prop}' is superseded by '#{replacing}'",
            suggestion: replacing
          )
        end

        return if vocabulary.property_defined?(prop) || replacing

        context.add(
          code: :unknown_property, severity: :error,
          path: "#{path}.#{prop}", message: "Unknown property '#{prop}' for type '#{node.type}'",
          suggestion: suggest_property(prop)
        )
      end

      def validate_property_domain(node, prop, path, context)
        return if vocabulary.property_allowed_for?(node.type, prop)

        context.add(
          code: :domain_mismatch, severity: context.severity,
          path: "#{path}.#{prop}",
          message: "Property '#{prop}' is not allowed for type '#{node.type}' or its ancestors"
        )
      end

      def validate_property_range(prop, value, path, context)
        ranges = vocabulary.expected_ranges(prop)
        case value
        when Array
          validate_array_range(prop, value, ranges, path, context)
        when List
          validate_list_range(prop, value, ranges, path, context)
        when Node
          validate_single_range(prop, value, ranges, "#{path}.#{prop}", context)
          validate(value, "#{path}.#{prop}", context)
        else
          validate_single_range(prop, value, ranges, "#{path}.#{prop}", context)
        end
      end

      def validate_array_range(prop, array, ranges, path, context)
        array.each_with_index do |item, idx|
          item_path = "#{path}.#{prop}[#{idx}]"
          validate_single_range(prop, item, ranges, item_path, context)
          validate(item, item_path, context) if item.is_a?(Node)
        end
      end

      def validate_list_range(prop, list, ranges, path, context)
        list.items.each_with_index do |item, idx|
          item_path = "#{path}.#{prop}.@list[#{idx}]"
          validate_single_range(prop, item, ranges, item_path, context)
          validate(item, item_path, context) if item.is_a?(Node)
        end
      end

      def validate_single_range(prop, value, ranges, path, context)
        return if range_checker.matches?(value, ranges)

        context.add(
          code: :range_mismatch, severity: context.severity,
          path: path,
          message: "Value for property '#{prop}' does not match expected range(s): #{ranges.join(', ')}"
        )
      end

      def suggest_type(type)
        @type_checker ||= DidYouMean::SpellChecker.new(dictionary: vocabulary.all_types)
        @type_checker.correct(type.to_s).first
      end

      def suggest_property(prop)
        @property_checker ||= DidYouMean::SpellChecker.new(dictionary: vocabulary.all_properties)
        @property_checker.correct(prop.to_s).first
      end
    end
  end
end
