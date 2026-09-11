# frozen_string_literal: true

require "active_support/core_ext/string/output_safety"

module StructuredData
  module Rails
    class Renderer
      class << self
        def render(document_or_node, pretty: StructuredData.config.pretty)
          return nil if document_or_node.nil?

          json = StructuredData::Serializer.dump(document_or_node, pretty: pretty)
          html = %(<script type="application/ld+json">#{json}</script>)

          ActiveSupport::SafeBuffer.new(html)
        end
      end
    end
  end
end
