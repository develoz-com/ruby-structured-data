# frozen_string_literal: true

require "json"
require_relative "reference"
require_relative "list"
require_relative "enum"
require_relative "values"

module StructuredData
  class Node
    attr_reader :type, :id, :attributes

    def initialize(type, id: nil, **attributes, &block)
      @type = normalize_type(type)
      @id = id
      @attributes = {}
      attributes.each { |key, value| set(key, value) }
      yield(self) if block_given?
    end

    def set(property, value)
      key = to_lower_camel_case(property)
      if id_key?(property, key)
        @id = value
      else
        @attributes[key] = value
      end
      self
    end

    def [](property)
      key = to_lower_camel_case(property)
      return id if id_key?(property, key)

      attributes[key] || attributes[property.to_s] || attributes[property.to_sym]
    end

    def ref
      raise ArgumentError, "Cannot create reference without id" unless id_present?

      StructuredData::Reference.new(id)
    end

    def to_h
      result = { "@type" => type }
      result["@id"] = id.to_s if id_present?

      attributes.keys.map(&:to_s).sort.each do |key|
        result[key] = serialize_value(attributes[key])
      end

      result
    end

    def as_json(*)
      to_h
    end

    def to_json(*)
      to_h.to_json(*)
    end

    def ==(other)
      other.is_a?(self.class) && to_h == other.to_h
    end
    alias eql? ==

    def hash
      [self.class, to_h].hash
    end

    private

    def id_present?
      !id.nil? && !id.to_s.strip.empty?
    end

    def id_key?(property, key)
      key == "id" || property.to_s == "@id"
    end

    def blank?(val)
      val.nil? || (val.respond_to?(:to_s) && val.to_s.strip.empty?)
    end

    def normalize_type(type)
      raise ArgumentError, "type cannot be blank" if blank?(type)

      clean = type.to_s.strip.sub(%r{\Ahttps?://schema\.org/}, "")
      parts = clean.split("_").reject(&:empty?)
      raise ArgumentError, "type cannot be blank" if parts.empty?

      parts.map { |part| part[0].upcase + part[1..] }.join
    end

    def to_lower_camel_case(prop)
      str = prop.to_s.strip
      parts = str.split("_").reject(&:empty?)
      return str if parts.empty?

      first_lower = parts.first[0].downcase + parts.first[1..]
      camel_rest(first_lower, parts[1..])
    end

    def camel_rest(first, rest)
      tail = rest.map { |part| part[0].upcase + part[1..] }
      ([first] + tail).join
    end

    def serialize_value(val)
      case val
      when Node, Reference, List, Enum, Values::Url, Values::Text
        val.to_h
      when Array
        val.map { |item| serialize_value(item) }
      when Hash
        val.transform_values { |item| serialize_value(item) }
      when URI::Generic
        val.to_s
      else
        serialize_fallback(val)
      end
    end

    def serialize_fallback(val)
      if val.respond_to?(:to_h)
        val.to_h
      else
        val
      end
    end
  end
end
