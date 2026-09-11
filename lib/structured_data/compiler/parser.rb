# frozen_string_literal: true

require_relative "terms"
require_relative "uri_helper"

module StructuredData
  class Compiler
    class Parser
      include UriHelper

      LINE_PATTERN = Regexp.new(
        "\\A(?<subject><(?>(?:[^>\\\\]|\\\\.)+)>|_:[a-zA-Z0-9_.-]+)\\s+" \
        "(?<predicate><(?>(?:[^>\\\\]|\\\\.)+)>)\\s+" \
        "(?<object><(?>(?:[^>\\\\]|\\\\.)+)>|_:[a-zA-Z0-9_.-]+|" \
        "\"(?>(?:[^\"\\\\]|\\\\.)*)\"(?:@[\\w-]+|\\^\\^<(?>(?:[^>\\\\]|\\\\.)+)>)?)" \
        "\\s*\\.\\s*(?:#.*)?\\z"
      )

      def initialize(vocab)
        @vocab = vocab
      end

      def parse(lines)
        lines.each_with_index do |line, index|
          parse_line(line, index + 1)
        end
      end

      def parse_line(line, line_number)
        stripped = line.strip
        return if stripped.empty? || stripped.start_with?("#")

        match = LINE_PATTERN.match(stripped)
        raise_syntax_error(line, line_number, stripped) unless match

        process_match(match)
      end

      private

      def raise_syntax_error(line, line_number, stripped)
        raise ParseError.new(
          "Invalid N-Triples syntax at line #{line_number}: #{stripped}",
          line_number: line_number,
          line: line
        )
      end

      def process_match(match)
        subject_raw = match[:subject]
        object_raw = match[:object]
        return if subject_raw.start_with?("_:") || object_raw.start_with?("_:")

        subject_term = extract_schema_term(extract_uri(subject_raw))
        predicate_uri = extract_uri(match[:predicate])
        return unless subject_term && predicate_uri

        dispatch_predicate(subject_term, predicate_uri, object_raw)
      end

      def dispatch_predicate(subject_term, predicate_uri, object_raw)
        case predicate_uri
        when Terms::PREDICATES[:subclass_of] then handle_subclass_of(subject_term, object_raw)
        when Terms::PREDICATES[:domain_includes] then handle_domain_includes(subject_term, object_raw)
        when Terms::PREDICATES[:range_includes] then handle_range_includes(subject_term, object_raw)
        when Terms::PREDICATES[:type] then handle_rdf_type(subject_term, object_raw)
        when Terms::PREDICATES[:superseded_by] then handle_superseded_by(subject_term, object_raw)
        when Terms::PREDICATES[:is_part_of] then handle_is_part_of(subject_term, object_raw)
        end
      end

      def handle_subclass_of(subject_term, object_raw)
        @vocab.add_class(subject_term)
        parent_term = extract_schema_term(extract_uri(object_raw))
        @vocab.add_subclass(subject_term, parent_term) if parent_term
      end

      def handle_domain_includes(subject_term, object_raw)
        @vocab.add_property(subject_term)
        domain_term = extract_schema_term(extract_uri(object_raw))
        @vocab.add_domain(subject_term, domain_term) if domain_term
      end

      def handle_range_includes(subject_term, object_raw)
        @vocab.add_property(subject_term)
        range_term = extract_schema_term(extract_uri(object_raw))
        @vocab.add_range(subject_term, range_term) if range_term
      end

      def handle_rdf_type(subject_term, object_raw)
        object_uri = extract_uri(object_raw)
        return unless object_uri

        case object_uri
        when Terms::TYPES[:rdfs_class], Terms::TYPES[:rdf_class]
          @vocab.add_class(subject_term)
        when Terms::TYPES[:rdf_property]
          @vocab.add_property(subject_term)
        else
          handle_enum_type(subject_term, object_uri)
        end
      end

      def handle_enum_type(subject_term, object_uri)
        enum_type = extract_schema_term(object_uri)
        @vocab.add_enum_member(enum_type, subject_term) if enum_type
      end

      def handle_superseded_by(subject_term, object_raw)
        replacement = extract_schema_term(extract_uri(object_raw))
        @vocab.add_superseded(subject_term, replacement) if replacement
      end

      def handle_is_part_of(subject_term, object_raw)
        section = extract_section(object_raw)
        @vocab.set_section(subject_term, section)
      end
    end
  end
end
