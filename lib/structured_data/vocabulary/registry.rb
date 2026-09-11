# frozen_string_literal: true

module StructuredData
  class Vocabulary
    class Registry
      def initialize
        @vocabularies = {}
      end

      def register(name, data)
        raise ArgumentError, "Vocabulary data must be a Hash" unless data.is_a?(Hash)

        @vocabularies[name.to_s] = normalize_vocab_data(data)
      end

      def find(category, key)
        if key.include?(":")
          prefix, local = key.split(":", 2)
          val = @vocabularies[prefix]&.dig(category, local)
          return val if val
        end

        @vocabularies.each_value do |vocab|
          val = vocab.dig(category, key)
          return val if val
        end
        nil
      end

      def enum_defined?(name)
        @vocabularies.each_value.any? { |vocab| vocab.dig("enums", name) }
      end

      def all_types
        @vocabularies.each_value.flat_map { |vocab| vocab["types"].keys }
      end

      def all_properties
        @vocabularies.each_value.flat_map { |vocab| vocab["properties"].keys }
      end

      private

      def normalize_vocab_data(data)
        {
          "types" => normalize_subhash(data["types"] || data[:types]),
          "properties" => normalize_subhash(data["properties"] || data[:properties]),
          "enums" => normalize_enums(data["enums"] || data[:enums]),
          "superseded" => normalize_string_map(data["superseded"] || data[:superseded])
        }
      end

      def normalize_subhash(hash)
        return {} unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(key, value), result|
          norm_key = normalize_term(key)
          result[norm_key] = value.is_a?(Hash) ? value.transform_keys(&:to_s) : value
        end
      end

      def normalize_enums(hash)
        return {} unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(key, members), result|
          result[normalize_term(key)] = normalize_term_list(members)
        end
      end

      def normalize_term_list(list)
        Array(list).map { |term| normalize_term(term) }
      end

      def normalize_string_map(hash)
        return {} unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(key, value), result|
          result[normalize_term(key)] = normalize_term(value)
        end
      end

      def normalize_term(term)
        return "" if term.nil?

        str = term.respond_to?(:name) && !term.is_a?(Class) ? term.name.to_s : term.to_s
        str.strip.sub(%r{\Ahttps?://schema\.org/}, "")
      end
    end
  end
end
