# frozen_string_literal: true

require "json"
require_relative "error"

module StructuredData
  class Document
    class DuplicateIdError < StructuredData::Error; end

    DEFAULT_CONTEXT = "https://schema.org"

    attr_reader :context

    def initialize(*nodes, context: DEFAULT_CONTEXT, graph: nil)
      @context = context
      @graph = graph
      @nodes = []
      nodes.flatten.each { |node| add(node) }
    end

    def nodes
      @nodes.dup.freeze
    end

    def graph?
      @nodes.size != 1 || @graph == true
    end

    def add(node)
      if node.is_a?(Array)
        node.each { |item| add(item) }
      else
        validate_node!(node)
        check_duplicate_id!(node)
        @nodes << node
      end
      self
    end
    alias << add

    def to_h
      if graph?
        {
          "@context" => context,
          "@graph" => @nodes.map(&:to_h)
        }
      else
        { "@context" => context }.merge(@nodes.first.to_h)
      end
    end

    def as_json(*)
      to_h
    end

    def to_json(*)
      to_h.to_json(*)
    end

    def ==(other)
      other.is_a?(self.class) &&
        context == other.context &&
        graph? == other.graph? &&
        nodes == other.nodes
    end
    alias eql? ==

    def hash
      [self.class, context, graph?, nodes].hash
    end

    private

    def validate_node!(node)
      raise ArgumentError, "Node cannot be nil" if node.nil?
      raise ArgumentError, "Node must respond to #to_h" unless node.respond_to?(:to_h)
    end

    def check_duplicate_id!(node)
      id = explicit_id(node)
      return unless id

      existing = @nodes.find { |n| explicit_id(n) == id }
      return unless existing && existing != node

      raise DuplicateIdError, "Conflicting duplicate @id detected: #{id}"
    end

    def explicit_id(node)
      return nil unless node.respond_to?(:id)

      raw_id = node.id
      return nil if raw_id.nil?

      str_id = raw_id.to_s.strip
      str_id.empty? ? nil : str_id
    end
  end
end
