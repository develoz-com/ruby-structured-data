# frozen_string_literal: true

require "uri"

module StructuredData
  class Reference
    attr_reader :id

    def initialize(id)
      validate_id!(id)
      @id = id
    end

    def to_h
      { "@id" => id.to_s }
    end

    def to_s
      id.to_s
    end

    def ==(other)
      other.is_a?(self.class) && id.to_s == other.id.to_s
    end
    alias eql? ==

    def hash
      [self.class, id.to_s].hash
    end

    private

    def validate_id!(val)
      raise ArgumentError, "id cannot be blank" if blank?(val)
      raise ArgumentError, "id must be a String or URI" unless string_or_uri?(val)
    end

    def blank?(val)
      val.nil? || (val.respond_to?(:to_s) && val.to_s.strip.empty?)
    end

    def string_or_uri?(val)
      val.is_a?(String) || val.is_a?(URI::Generic)
    end
  end
end
