# frozen_string_literal: true

module StructuredData
  class Vocabulary
    module Hierarchy
      def self.ancestors(type_name, vocabulary)
        normalized = vocabulary.normalize_term(type_name)
        return [] if normalized.empty?

        result = []
        visited = Set.new([normalized])
        queue = direct_parents(normalized, vocabulary)

        until queue.empty?
          current = queue.shift
          next if visited.include?(current)

          visited.add(current)
          result << current
          queue.concat(direct_parents(current, vocabulary))
        end

        result
      end

      def self.direct_parents(type_name, vocabulary)
        info = vocabulary.type_info(type_name)
        Array(info && (info["parents"] || info[:parents])).map { |p| vocabulary.normalize_term(p) }
      end
    end
  end
end
