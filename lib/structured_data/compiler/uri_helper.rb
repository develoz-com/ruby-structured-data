# frozen_string_literal: true

module StructuredData
  class Compiler
    module UriHelper
      ESCAPE_CHARS = {
        "t" => "\t",
        "b" => "\b",
        "n" => "\n",
        "r" => "\r",
        "f" => "\f",
        "\"" => "\"",
        "'" => "'",
        "\\" => "\\"
      }.freeze

      def extract_uri(raw)
        return unless raw.start_with?("<")

        normalize_uri(unescape(raw[1..-2]))
      end

      def normalize_uri(uri)
        normalized = uri.sub(%r{\Ahttp://schema\.org(/|\z)}, "https://schema.org\\1")
        normalized.sub(%r{\Ahttps://www\.w3\.org/}, "http://www.w3.org/")
      end

      def extract_schema_term(uri)
        return unless uri =~ %r{\Ahttps://schema\.org/([^/]+)\z}

        Regexp.last_match(1)
      end

      def extract_section(object_raw)
        return object_raw[1..-2] if object_raw.start_with?('"') && object_raw.end_with?('"')

        uri = unescape(object_raw.delete_prefix("<").delete_suffix(">"))
        section_from_subdomain(uri) || section_from_path(uri) || Vocabulary::CORE_SECTION
      end

      def section_from_subdomain(uri)
        return unless uri =~ %r{\Ahttps?://([a-zA-Z0-9_-]+)\.schema\.org}

        subdomain = Regexp.last_match(1)
        subdomain unless subdomain == "www"
      end

      def section_from_path(uri)
        return unless uri =~ %r{\Ahttps?://(?:www\.)?schema\.org/(.+?)/?\z}

        Regexp.last_match(1)
      end

      def unescape(str)
        str.gsub(/\\(?:([tbnrf"'\\])|u([0-9A-Fa-f]{4})|U([0-9A-Fa-f]{8}))/) do
          if (char = Regexp.last_match(1))
            ESCAPE_CHARS[char]
          else
            hex = Regexp.last_match(2) || Regexp.last_match(3)
            [hex.hex].pack("U*")
          end
        end
      end
    end
  end
end
