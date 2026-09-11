# frozen_string_literal: true

RSpec.describe StructuredData::Node do
  describe "#initialize" do
    it "normalizes symbol type to PascalCase string" do
      node = described_class.new(:organization)
      expect(node.type).to eq("Organization")
    end

    it "normalizes snake_case symbol type to PascalCase" do
      node = described_class.new(:local_business)
      expect(node.type).to eq("LocalBusiness")
    end

    it "normalizes full Schema.org URI type" do
      node = described_class.new("https://schema.org/SportsEvent")
      expect(node.type).to eq("SportsEvent")
    end

    it "stores optional id as string or URI" do
      node1 = described_class.new(:Person, id: "https://example.com/alice")
      node2 = described_class.new(:Person, id: URI("https://example.com/bob"))
      expect(node1.id).to eq("https://example.com/alice")
      expect(node2.id).to eq(URI("https://example.com/bob"))
    end

    it "yields self to the block when given" do
      node = described_class.new(:Product) do |p|
        p.set(:name, "Super Widget")
      end
      expect(node[:name]).to eq("Super Widget")
    end

    it "initializes with keyword attributes" do
      node = described_class.new(:Event, name: "Concert", start_date: "2026-10-01")
      expect(node[:name]).to eq("Concert")
      expect(node[:start_date]).to eq("2026-10-01")
    end

    it "raises ArgumentError when type is nil or empty" do
      expect { described_class.new(nil) }
        .to raise_error(ArgumentError, /type cannot be blank/)
      expect { described_class.new("") }
        .to raise_error(ArgumentError, /type cannot be blank/)
    end

    it "raises ArgumentError when type is whitespace or underscore only" do
      expect { described_class.new("   ") }
        .to raise_error(ArgumentError, /type cannot be blank/)
      expect { described_class.new("___") }
        .to raise_error(ArgumentError, /type cannot be blank/)
    end
  end

  describe "#set and #[]" do
    let(:node) { described_class.new(:Service) }

    it "returns self when chaining set" do
      expect(node.set(:service_type, "Plumbing")).to be(node)
    end

    it "converts snake_case properties to lowerCamelCase" do
      node.set(:service_type, "Plumbing")
      expect(node[:service_type]).to eq("Plumbing")
      expect(node[:serviceType]).to eq("Plumbing")
      expect(node["service_type"]).to eq("Plumbing")
    end

    it "retains camelCase properties as lowerCamelCase" do
      node.set("totalPaymentDue", 100)
      expect(node[:total_payment_due]).to eq(100)
      expect(node[:totalPaymentDue]).to eq(100)
    end

    it "sets @id when property is id and retrieves via []" do
      node.set(:id, "https://example.com/srv/1")
      expect(node.id).to eq("https://example.com/srv/1")
      expect(node[:id]).to eq("https://example.com/srv/1")
      expect(node["@id"]).to eq("https://example.com/srv/1")
    end

    it "sets @id when property is @id string" do
      fresh = described_class.new(:Place)
      fresh.set("@id", "https://example.com/place/1")
      expect(fresh.id).to eq("https://example.com/place/1")
    end

    it "handles empty or underscore-only property access safely" do
      expect(node[""]).to be_nil
      expect(node["___"]).to be_nil
    end

    it "returns nil for non-existent property" do
      expect(node[:non_existent]).to be_nil
    end
  end

  describe "#ref" do
    it "returns a StructuredData::Reference when id is present" do
      node = described_class.new(:Organization, id: "https://example.com/org")
      ref = node.ref
      expect(ref).to be_a(StructuredData::Reference)
      expect(ref.id).to eq("https://example.com/org")
    end

    it "raises ArgumentError when id is nil" do
      node = described_class.new(:Organization)
      expect { node.ref }
        .to raise_error(ArgumentError, "Cannot create reference without id")
    end

    it "raises ArgumentError when id is blank whitespace" do
      node = described_class.new(:Organization, id: "  ")
      expect { node.ref }
        .to raise_error(ArgumentError, "Cannot create reference without id")
    end
  end

  describe "#to_h" do
    it "orders @type and @id first followed by sorted property keys" do
      node = described_class.new(:Organization, id: "https://example.com/org")
      node.set(:url, "https://example.com").set(:name, "Acme Corp").set(:start_date, "2000-01-01")

      hash = node.to_h
      expect(hash.keys).to eq(%w[@type @id name startDate url])
      expect(hash["@type"]).to eq("Organization")
      expect(hash["@id"]).to eq("https://example.com/org")
    end

    it "omits @id when id is nil" do
      node = described_class.new(:Thing, name: "Sample")
      expect(node.to_h.keys).to eq(%w[@type name])
    end

    it "recursively converts nested Nodes and References" do
      founder = described_class.new(:Person, id: "https://example.com/alice", name: "Alice")
      parent = described_class.new(:Organization, id: "https://example.com/parent")
      org = described_class.new(:Organization, founder: founder, parent_organization: parent.ref)

      expect(org.to_h).to eq(
        {
          "@type" => "Organization",
          "founder" => { "@type" => "Person", "@id" => "https://example.com/alice", "name" => "Alice" },
          "parentOrganization" => { "@id" => "https://example.com/parent" }
        }
      )
    end

    it "recursively converts Lists and Enums" do
      node = described_class.new(:Product)
      node.set(:recipe_instructions, StructuredData::Values.list("Step 1", "Step 2"))
      node.set(:availability, StructuredData::Values.enum(:InStock))

      hash = node.to_h
      expect(hash["recipeInstructions"]).to eq({ "@list" => ["Step 1", "Step 2"] })
      expect(hash["availability"]).to eq("https://schema.org/InStock")
    end

    it "recursively converts Value wrappers" do
      node = described_class.new(:Product)
      node.set(:url, StructuredData::Values.url("https://example.com/product"))
      node.set(:name, StructuredData::Values.text("Pro Product"))

      hash = node.to_h
      expect(hash["url"]).to eq("https://example.com/product")
      expect(hash["name"]).to eq("Pro Product")
    end

    it "recursively converts arrays, hashes, and URI objects" do
      node = described_class.new(:Thing)
      tag1 = described_class.new(:Tag, name: "Ruby")
      node.set(:tags, [tag1, "Gem"])
      node.set(:metadata, { author: URI("https://example.com/author") })

      hash = node.to_h
      expect(hash["tags"]).to eq([{ "@type" => "Tag", "name" => "Ruby" }, "Gem"])
      expect(hash["metadata"]).to eq({ author: "https://example.com/author" })
    end

    it "converts custom objects responding to to_h or leaves primitive as is" do
      custom = Class.new { def to_h = { "custom" => true } }.new
      node = described_class.new(:Thing, custom_prop: custom, count: 42)
      expect(node.to_h["customProp"]).to eq({ "custom" => true })
      expect(node.to_h["count"]).to eq(42)
    end
  end

  describe "serialization and equality" do
    let(:base_node) { described_class.new(:Person, id: "https://example.com/1", name: "Bob") }
    let(:matching_node) { described_class.new(:Person, id: "https://example.com/1", name: "Bob") }
    let(:different_node) { described_class.new(:Person, id: "https://example.com/2", name: "Charlie") }

    it "implements as_json and to_json" do
      expect(base_node.as_json).to eq(base_node.to_h)
      json = base_node.to_json
      expect(JSON.parse(json)).to eq(base_node.to_h)
    end

    it "implements value equality with ==" do
      expect(base_node).to eq(matching_node)
      expect(base_node).not_to eq(different_node)
      expect(base_node == "not a node").to be(false)
    end

    it "implements eql?" do
      expect(base_node.eql?(matching_node)).to be(true)
      expect(base_node.eql?(different_node)).to be(false)
    end

    it "implements hash" do
      expect(base_node.hash).to eq(matching_node.hash)
      expect(base_node.hash).not_to eq(different_node.hash)
    end
  end
end
