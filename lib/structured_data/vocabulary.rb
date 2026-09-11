# frozen_string_literal: true

require "forwardable"
require_relative "vocabulary/registry"
require_relative "vocabulary/data_loader"
require_relative "vocabulary/hierarchy"

module StructuredData
  class Vocabulary
    class << self
      extend Forwardable

      def default
        @default ||= new
      end

      def reset!
        @default = nil
      end

      def_delegators :default,
                     :type_defined?, :type_info, :ancestors, :property_defined?, :property_info,
                     :property_allowed_for?, :expected_ranges, :enum_type?, :enum_member?,
                     :superseded_by, :register_vocabulary, :all_types, :all_properties
    end

    def initialize(source = nil)
      @registry = Registry.new
      @data = DataLoader.load(source)
    end

    def type_defined?(type_name)
      !type_info(type_name).nil?
    end

    def type_info(type_name)
      lookup_category("types", type_name)
    end

    def ancestors(type_name)
      Hierarchy.ancestors(type_name, self)
    end

    def property_defined?(property_name)
      !property_info(property_name).nil?
    end

    def property_info(property_name)
      lookup_category("properties", property_name)
    end

    def property_allowed_for?(type_name, property_name)
      info = property_info(property_name)
      return false unless info

      domains = Array(info["domains"] || info[:domains]).map { |d| normalize_term(d) }
      norm_type = normalize_term(type_name)
      return true if domains.include?(norm_type)

      ancestors(norm_type).any? { |ancestor| domains.include?(ancestor) }
    end

    def expected_ranges(property_name)
      info = property_info(property_name)
      return [] unless info

      Array(info["ranges"] || info[:ranges]).map { |r| normalize_term(r) }
    end

    def enum_type?(type_name)
      norm = normalize_term(type_name)
      return false if norm.empty?

      !@data.dig("enums", norm).nil? || @registry.enum_defined?(norm) ||
        norm == "Enumeration" || ancestors(norm).include?("Enumeration")
    end

    def enum_member?(enum_type_name, member_name)
      norm_enum = normalize_term(enum_type_name)
      norm_member = normalize_term(member_name)
      return false if norm_enum.empty? || norm_member.empty?

      return true if enum_members(norm_enum).include?(norm_member)

      ancestors(norm_enum).any? do |ancestor|
        enum_members(ancestor).include?(norm_member)
      end
    end

    def superseded_by(term)
      norm = normalize_term(term)
      return nil if norm.empty?

      @registry.find("superseded", norm) || @data.dig("superseded", norm)
    end

    def register_vocabulary(name, data)
      @registry.register(name, data)
      self
    end

    def all_types
      category_keys("types")
    end

    def all_properties
      category_keys("properties")
    end

    def normalize_term(term)
      return "" if term.nil?

      str = term.respond_to?(:name) && !term.is_a?(Class) ? term.name.to_s : term.to_s
      str.strip.sub(%r{\Ahttps?://schema\.org/}, "")
    end

    private

    def lookup_category(category, term)
      norm = normalize_term(term)
      return nil if norm.empty?

      @registry.find(category, norm) || @data.dig(category, norm)
    end

    def category_keys(category)
      keys = @data[category] ? @data[category].keys : []
      (keys + @registry.public_send("all_#{category}")).uniq.sort
    end

    def enum_members(norm_enum)
      members = @registry.find("enums", norm_enum) || @data.dig("enums", norm_enum) || []
      Array(members).map { |m| normalize_term(m) }
    end
  end
end
