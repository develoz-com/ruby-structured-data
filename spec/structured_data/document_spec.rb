# frozen_string_literal: true

require "uri"

RSpec.describe StructuredData::Document do
  let(:person_node) { StructuredData::Node.new("Person", id: "person-1", name: "Alice") }
  let(:org_node) { StructuredData::Node.new("Organization", id: "org-1", name: "Acme Corp") }
  let(:blank_node) { StructuredData::Node.new("Thing", name: "Anonymous") }

  describe "#initialize" do
    it "accepts a single node" do
      doc = described_class.new(person_node)
      expect(doc.nodes).to eq([person_node])
    end

    it "accepts multiple nodes via splat or array" do
      doc1 = described_class.new(person_node, org_node)
      doc2 = described_class.new([person_node, org_node])
      expect(doc1.nodes).to eq([person_node, org_node])
      expect(doc2.nodes).to eq([person_node, org_node])
    end

    it "defaults to schema.org context and allows custom context" do
      doc = described_class.new(person_node)
      custom_doc = described_class.new(person_node, context: "https://schema.org/v1")
      expect(doc.context).to eq("https://schema.org")
      expect(custom_doc.context).to eq("https://schema.org/v1")
    end
  end

  describe "#nodes and node storage" do
    it "preserves insertion order of nodes" do
      doc = described_class.new(person_node)
      doc.add(org_node)
      expect(doc.nodes).to eq([person_node, org_node])
    end

    it "returns a frozen copy of the nodes array" do
      doc = described_class.new(person_node)
      expect(doc.nodes).to be_frozen
      expect { doc.nodes << org_node }.to raise_error(FrozenError)
    end
  end

  describe "#add and #<<" do
    it "adds a single node and returns self" do
      doc = described_class.new
      result = doc.add(person_node)
      expect(result).to equal(doc)
      expect(doc.nodes).to eq([person_node])
    end

    it "supports << alias" do
      doc = described_class.new
      doc << person_node
      expect(doc.nodes).to eq([person_node])
    end

    it "adds an array of nodes" do
      doc = described_class.new
      doc.add([person_node, org_node])
      expect(doc.nodes).to eq([person_node, org_node])
    end

    it "raises ArgumentError when adding nil or non-node" do
      doc = described_class.new
      expect { doc.add(nil) }.to raise_error(ArgumentError, /cannot be nil/)
      expect { doc.add(Object.new) }.to raise_error(ArgumentError, /respond to #to_h/)
    end
  end

  describe "rendering mode (#graph? and #to_h)" do
    it "renders single entity by default when exactly 1 node" do
      doc = described_class.new(person_node)
      expect(doc.graph?).to be false
      expected = {
        "@context" => "https://schema.org",
        "@type" => "Person",
        "@id" => "person-1",
        "name" => "Alice"
      }
      expect(doc.to_h).to eq(expected)
    end

    it "renders @graph when exactly 1 node and graph: true" do
      doc = described_class.new(person_node, graph: true)
      expect(doc.graph?).to be true
      expected = {
        "@context" => "https://schema.org",
        "@graph" => [person_node.to_h]
      }
      expect(doc.to_h).to eq(expected)
    end

    it "renders @graph when multiple nodes are present" do
      doc = described_class.new(person_node, org_node)
      expect(doc.graph?).to be true
      expected = {
        "@context" => "https://schema.org",
        "@graph" => [person_node.to_h, org_node.to_h]
      }
      expect(doc.to_h).to eq(expected)
    end

    it "renders @graph when 0 nodes are present" do
      doc = described_class.new
      expect(doc.graph?).to be true
      expect(doc.to_h).to eq({ "@context" => "https://schema.org", "@graph" => [] })
    end
  end

  describe "unique @id validation" do
    it "allows multiple nodes without explicit ids" do
      blank1 = StructuredData::Node.new("Thing", name: "First")
      blank2 = StructuredData::Node.new("Thing", name: "Second")
      expect { described_class.new(blank1, blank2) }.not_to raise_error
    end

    it "handles nodes without id method or with whitespace id safely" do
      duck_node = Class.new { def to_h = { "@type" => "Duck" } }.new
      ws_node = Class.new do
        def to_h = { "@type" => "WS" }
        def id = "   "
      end.new
      doc = described_class.new(duck_node, ws_node)
      expect(doc.nodes.size).to eq(2)
    end

    it "allows multiple nodes with distinct ids" do
      expect { described_class.new(person_node, org_node) }.not_to raise_error
    end

    it "allows identical nodes with the same id" do
      identical = StructuredData::Node.new("Person", id: "person-1", name: "Alice")
      expect { described_class.new(person_node, identical) }.not_to raise_error
    end

    it "raises DuplicateIdError when initialized with conflicting duplicate ids" do
      conflicting = StructuredData::Node.new("Person", id: "person-1", name: "Bob")
      expect { described_class.new(person_node, conflicting) }
        .to raise_error(StructuredData::Document::DuplicateIdError, /person-1/)
    end

    it "raises DuplicateIdError when adding conflicting node via #add" do
      doc = described_class.new(person_node)
      conflicting = StructuredData::Node.new("Person", id: "person-1", name: "Bob")
      expect { doc.add(conflicting) }
        .to raise_error(StructuredData::Document::DuplicateIdError, /person-1/)
    end

    it "raises DuplicateIdError when conflicting types share the same id" do
      conflicting = StructuredData::Node.new("Organization", id: "person-1", name: "Alice")
      expect { described_class.new(person_node, conflicting) }
        .to raise_error(StructuredData::Document::DuplicateIdError, /person-1/)
    end

    it "matches URI and String ids when validating uniqueness" do
      uri_node = StructuredData::Node.new("Thing", id: URI("https://example.com/item/1"), name: "URI Item")
      str_node = StructuredData::Node.new("Thing", id: "https://example.com/item/1", name: "Different Item")
      expect { described_class.new(uri_node, str_node) }
        .to raise_error(StructuredData::Document::DuplicateIdError)
    end
  end

  describe "JSON serialization" do
    it "delegates as_json to to_h" do
      doc = described_class.new(person_node)
      expect(doc.as_json).to eq(doc.to_h)
    end

    it "delegates to_json to to_h.to_json" do
      doc = described_class.new(person_node)
      expect(doc.to_json).to eq(doc.to_h.to_json)
    end
  end

  describe "value equality (== and hash)" do
    it "considers documents with same context, graph mode, and nodes equal" do
      doc1 = described_class.new(person_node)
      doc2 = described_class.new(person_node)
      expect(doc1).to eq(doc2)
      expect(doc1).to eql(doc2)
      expect(doc1.hash).to eq(doc2.hash)
    end

    it "returns false when comparing to different documents or objects" do
      doc = described_class.new(person_node)
      diff_context = described_class.new(person_node, context: "https://schema.org/v2")
      diff_graph = described_class.new(person_node, graph: true)
      expect(doc).not_to eq(diff_context)
      expect(doc).not_to eq(diff_graph)
      expect(doc).not_to eq("some string")
    end

    it "returns false when nodes differ" do
      doc1 = described_class.new(person_node)
      doc2 = described_class.new(org_node)
      expect(doc1).not_to eq(doc2)
    end
  end
end
