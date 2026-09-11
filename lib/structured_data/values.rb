# frozen_string_literal: true

require "uri"
require "json"
require_relative "reference"
require_relative "list"
require_relative "enum"

module StructuredData
  module Values
    class Url
      attr_reader :value

      def initialize(value)
        validate_url!(value)
        @value = value.to_s
      end

      def to_s
        value
      end
      alias to_str to_s

      def to_h
        value
      end

      def as_json(*)
        value
      end

      def to_json(*)
        value.to_json(*)
      end

      def ==(other)
        if other.is_a?(self.class)
          value == other.value
        elsif other.is_a?(String)
          value == other
        else
          false
        end
      end

      def eql?(other)
        other.is_a?(self.class) && value == other.value
      end

      def hash
        [self.class, value].hash
      end

      private

      def validate_url!(val)
        raise ArgumentError, "URL cannot be blank" if val.nil? || val.to_s.strip.empty?

        check_parsed_uri!(parse_uri(val), val)
      end

      def parse_uri(val)
        val.is_a?(URI::Generic) ? val : URI.parse(val.to_s)
      rescue URI::InvalidURIError => e
        raise ArgumentError, "Invalid URL format: #{val} (#{e.message})"
      end

      def check_parsed_uri!(uri, raw)
        raise ArgumentError, "Invalid URL format: #{raw}" if uri.scheme.nil? || uri.scheme.empty?
        raise ArgumentError, "Invalid URL format: #{raw}" if empty_location?(uri)
      end

      def empty_location?(uri)
        (uri.host.nil? || uri.host.empty?) && (uri.path.nil? || uri.path.empty?)
      end
    end

    class Text
      attr_reader :value

      def initialize(value)
        raise ArgumentError, "Text cannot be nil" if value.nil?

        @value = value.to_s
      end

      def to_s
        value
      end
      alias to_str to_s

      def to_h
        value
      end

      def as_json(*)
        value
      end

      def to_json(*)
        value.to_json(*)
      end

      def ==(other)
        if other.is_a?(self.class)
          value == other.value
        elsif other.is_a?(String)
          value == other
        else
          false
        end
      end

      def eql?(other)
        other.is_a?(self.class) && value == other.value
      end

      def hash
        [self.class, value].hash
      end
    end

    module_function

    def url(val)
      val.is_a?(Url) ? val : Url.new(val)
    end

    def text(val)
      val.is_a?(Text) ? val : Text.new(val)
    end

    def ref(id)
      StructuredData::Reference.new(id)
    end

    def list(*items)
      StructuredData::List.new(items.flatten)
    end

    def enum(name, type = nil)
      StructuredData::Enum.new(name, type)
    end
  end

  Url = Values::Url
  Text = Values::Text
end
