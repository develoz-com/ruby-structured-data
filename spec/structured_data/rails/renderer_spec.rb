# frozen_string_literal: true

require "rails"
require "active_support/core_ext/string/output_safety"
require "structured_data/rails/renderer"

RSpec.describe StructuredData::Rails::Renderer do
  describe ".render" do
    it "returns nil when target is nil" do
      expect(described_class.render(nil)).to be_nil
    end

    it "renders a Node as an ActiveSupport::SafeBuffer" do
      node = StructuredData.node("Person", name: "Alice")
      result = described_class.render(node)

      expect(result).to be_a(ActiveSupport::SafeBuffer).and be_html_safe
      expect(result).to start_with('<script type="application/ld+json">').and end_with("</script>")
    end

    it "renders a Document with context and node properties" do
      node = StructuredData.node("Organization", name: "Acme")
      doc = StructuredData.document(node)
      result = described_class.render(doc)

      expect(result).to include('"@context":"https://schema.org"')
      expect(result).to include('"@type":"Organization"')
      expect(result).to include('"name":"Acme"')
    end

    it "formats with indentation when pretty is true" do
      node = StructuredData.node("Person", name: "Alice")
      result = described_class.render(node, pretty: true)

      expect(result).to include("\n")
      expect(result).to include('  "@type": "Person"')
    end

    it "neutralizes </script> tags to prevent script breakout" do
      node = StructuredData.node("Article", headline: 'Hack </script><script>alert("XSS")</script>')
      result = described_class.render(node)

      expect(result).not_to include("</script><script>")
      expect(result).to include('<\/script>')
    end

    it "neutralizes case-insensitive </Script> tags" do
      node = StructuredData.node("Article", headline: "Bad </Script> tag")
      result = described_class.render(node)

      expect(result).not_to include("</Script>")
      expect(result).to include('<\/script>')
    end
  end
end
