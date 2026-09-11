# frozen_string_literal: true

module StructuredData
  class List
    include Enumerable

    attr_reader :items

    def initialize(items = [])
      raise ArgumentError, "items must be Enumerable" unless items.is_a?(Enumerable) || items.respond_to?(:to_a)

      @items = items.to_a
    end

    def each(&)
      items.each(&)
    end

    def to_h
      {
        "@list" => items.map { |item| serialize_item(item) }
      }
    end

    def ==(other)
      other.is_a?(self.class) && items == other.items
    end
    alias eql? ==

    def hash
      [self.class, items].hash
    end

    private

    def serialize_item(item)
      if item.is_a?(Array)
        item.map { |nested| serialize_item(nested) }
      elsif item.respond_to?(:to_h)
        item.to_h
      else
        item
      end
    end
  end
end
