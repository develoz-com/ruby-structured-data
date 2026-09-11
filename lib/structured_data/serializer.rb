# frozen_string_literal: true

require "json"

module StructuredData
  class Serializer
    class << self
      def dump(target, pretty: false)
        new(pretty: pretty).dump(target)
      end
    end

    attr_reader :pretty

    def initialize(pretty: false)
      @pretty = pretty
    end

    def dump(target, pretty: @pretty)
      hash = to_hash(target)
      json = pretty ? JSON.pretty_generate(hash) : JSON.generate(hash)
      escape_html_script(json)
    end

    private

    def to_hash(target)
      if target.is_a?(Hash)
        target
      elsif target.respond_to?(:to_h)
        target.to_h
      else
        raise ArgumentError, "Target cannot be serialized to Hash: #{target.inspect}"
      end
    end

    def escape_html_script(json)
      json.gsub(%r{</script}i) { "<\\/script" }
          .gsub("<!--") { "<\\!--" }
          .gsub("\u2028") { "\\u2028" }
          .gsub("\u2029") { "\\u2029" }
    end
  end
end
