# frozen_string_literal: true

require "json"

RSpec.describe StructuredData::Serializer do
  let(:person_node) { StructuredData::Node.new(:Person, name: "Alice", id: "https://example.com/alice") }
  let(:document) { StructuredData::Document.new(person_node) }

  describe ".dump" do
    it "serializes a Node to compact JSON string" do
      result = described_class.dump(person_node)
      expect(result).to eq('{"@type":"Person","@id":"https://example.com/alice","name":"Alice"}')
    end

    it "serializes a Document to compact JSON string" do
      result = described_class.dump(document)
      expect(result).to include('"@context":"https://schema.org"')
      expect(result).to include('"@type":"Person"')
    end

    it "serializes a Hash directly" do
      hash = { "@context" => "https://schema.org", "@type" => "Place", "name" => "Paris" }
      result = described_class.dump(hash)
      expect(result).to eq('{"@context":"https://schema.org","@type":"Place","name":"Paris"}')
    end

    it "supports pretty generation" do
      result = described_class.dump(person_node, pretty: true)
      expect(result).to include("\n")
      expect(result).to include("  \"@type\": \"Person\"")
    end

    it "raises ArgumentError when target does not respond to #to_h" do
      expect { described_class.dump(12_345) }.to raise_error(ArgumentError, /Target cannot be serialized to Hash/)
    end
  end

  describe "HTML-safe script escaping" do
    it "neutralizes lowercase </script> tags" do
      node = StructuredData::Node.new(:Article, article_body: "First</script><script>alert('xss')")
      result = described_class.dump(node)
      expect(result).not_to include("</script")
      expect(result).to include('<\\/script><script>')
    end

    it "neutralizes uppercase </SCRIPT> tags" do
      node = StructuredData::Node.new(:Article, article_body: "First</SCRIPT>")
      result = described_class.dump(node)
      expect(result).not_to include("</SCRIPT>")
      expect(result).to include('<\\/script>')
    end

    it "neutralizes mixed case </Script> tags" do
      node = StructuredData::Node.new(:Article, article_body: "First</Script>")
      result = described_class.dump(node)
      expect(result).not_to include("</Script>")
      expect(result).to include('<\\/script>')
    end

    it "neutralizes HTML comment openers <!--" do
      node = StructuredData::Node.new(:Article, article_body: "<!-- comment -->")
      result = described_class.dump(node)
      expect(result).not_to include("<!--")
      expect(result).to include('<\\!-- comment -->')
    end

    it "escapes unicode line separator U+2028 and paragraph separator U+2029" do
      node = StructuredData::Node.new(:Article, article_body: "Line1\u2028Line2\u2029Line3")
      result = described_class.dump(node)
      expect(result).not_to include("\u2028")
      expect(result).to include('\\u2028')
      expect(result).to include('\\u2029')
    end

    it "produces valid parseable JSON when comment openers are not present" do
      node = StructuredData::Node.new(:Article, article_body: "</script>\u2028\u2029")
      result = described_class.dump(node)
      parsed = JSON.parse(result)
      expect(parsed["articleBody"]).to eq("</script>\u2028\u2029")
    end
  end

  describe "instance usage" do
    it "allows instantiating serializer with pretty configuration" do
      serializer = described_class.new(pretty: true)
      expect(serializer.pretty).to be true
      expect(serializer.dump(person_node)).to include("\n")
    end

    it "allows overriding pretty flag in instance dump method" do
      serializer = described_class.new(pretty: true)
      expect(serializer.dump(person_node, pretty: false)).not_to include("\n")
    end
  end
end
