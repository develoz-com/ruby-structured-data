# frozen_string_literal: true

require "json"

module StructuredData
  class Enum
    SCHEMA_ORG_URI_PREFIX = "https://schema.org/"

    attr_reader :name, :type, :uri

    def initialize(name, type = nil)
      raise ArgumentError, "name cannot be blank" if name.nil? || name.to_s.strip.empty?

      @name = normalize_term(name)
      @type = blank?(type) ? nil : normalize_term(type)
      @uri = "#{SCHEMA_ORG_URI_PREFIX}#{@name}"
    end

    def to_s
      uri
    end
    alias to_str to_s

    def to_h
      uri
    end

    def as_json(*)
      uri
    end

    def to_json(*)
      uri.to_json(*)
    end

    def ==(other)
      if other.is_a?(self.class)
        uri == other.uri
      elsif other.is_a?(String)
        uri == other
      else
        false
      end
    end

    def eql?(other)
      other.is_a?(self.class) && uri == other.uri
    end

    def hash
      [self.class, uri].hash
    end

    private

    def blank?(val)
      val.nil? || (val.respond_to?(:to_s) && val.to_s.strip.empty?)
    end

    def normalize_term(term)
      term.to_s.strip.sub(%r{\Ahttps?://schema\.org/}, "")
    end
  end
end
