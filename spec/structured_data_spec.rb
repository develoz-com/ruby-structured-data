# frozen_string_literal: true

RSpec.describe StructuredData do
  after { described_class.reset_config! }

  describe "configuration" do
    it "defaults to :schema_org validation_mode and false pretty" do
      expect(described_class.config.validation_mode).to eq(:schema_org)
      expect(described_class.config.pretty).to be false
    end

    it "allows configuring via block" do
      described_class.configure do |config|
        config.validation_mode = :strict
        config.pretty = true
      end
      expect(described_class.config.validation_mode).to eq(:strict)
      expect(described_class.config.pretty).to be true
    end

    it "returns config when configure called without block" do
      expect(described_class.configure).to eq(described_class.config)
    end

    it "resets configuration" do
      described_class.configure { |c| c.pretty = true }
      described_class.reset_config!
      expect(described_class.config.pretty).to be false
    end
  end

  describe "builder and factory methods" do
    it "creates a Node via .node" do
      node = described_class.node(:Person, name: "Alice", id: "https://example.com/alice") do |n|
        n.set(:job_title, "Engineer")
      end
      expect(node).to be_a(StructuredData::Node)
      expect(node[:name]).to eq("Alice")
      expect(node[:jobTitle]).to eq("Engineer")
    end

    it "creates a Document via .document" do
      node = described_class.node(:Person, name: "Alice")
      doc = described_class.document(node)
      expect(doc).to be_a(StructuredData::Document)
      expect(doc.nodes.size).to eq(1)
    end

    it "creates a Reference via .ref" do
      ref = described_class.ref("https://example.com/ref")
      expect(ref).to be_a(StructuredData::Reference)
      expect(ref.to_h).to eq({ "@id" => "https://example.com/ref" })
    end

    it "creates a List via .list" do
      list = described_class.list(1, 2, 3)
      expect(list).to be_a(StructuredData::List)
      expect(list.to_h).to eq({ "@list" => [1, 2, 3] })
    end

    it "creates an Enum via .enum" do
      enum = described_class.enum(:InStock, :ItemAvailability)
      expect(enum).to be_a(StructuredData::Enum)
      expect(enum.to_s).to eq("https://schema.org/InStock")
    end

    it "creates a Url value via .url" do
      url = described_class.url("https://example.com")
      expect(url).to be_a(StructuredData::Values::Url)
      expect(url.to_s).to eq("https://example.com")
    end

    it "creates a Text value via .text" do
      text = described_class.text("Hello world")
      expect(text).to be_a(StructuredData::Values::Text)
      expect(text.to_s).to eq("Hello world")
    end

    it "returns the default vocabulary via .vocabulary" do
      expect(described_class.vocabulary).to equal(StructuredData::Vocabulary.default)
    end
  end

  describe "validation and serialization delegates" do
    it "validates using config default mode" do
      node = described_class.node(:Person, name: "Alice")
      result = described_class.validate(node)
      expect(result).to be_valid
    end

    it "raises ValidationError on invalid node with .validate!" do
      node = described_class.node(:Person, invalid_property_key: 123)
      expect { described_class.validate!(node) }.to raise_error(StructuredData::ValidationError)
    end

    it "dumps target using serializer and respects config pretty" do
      described_class.configure { |c| c.pretty = true }
      node = described_class.node(:Person, name: "Alice")
      dumped = described_class.dump(node)
      expect(dumped).to include("\n")
      expect(dumped).to include('"name": "Alice"')
    end
  end

  describe "end-to-end authoring and serialization flow" do
    let(:doc) do
      org = described_class.node(
        :Organization,
        id: "https://develoz.com/#org",
        name: "Develoz",
        url: described_class.url("https://develoz.com"),
        slogan: "Engineering Excellence"
      )
      service = described_class.node(
        :ProfessionalService,
        id: "https://develoz.com/#service",
        name: "Develoz Consulting",
        parent_organization: described_class.ref("https://develoz.com/#org")
      )
      described_class.document(org, service)
    end

    it "validates a full Schema.org Document" do
      expect(described_class.validate!(doc)).to be_valid
    end

    it "serializes a full Schema.org Document to JSON-LD" do
      json_ld = described_class.dump(doc)
      expect(json_ld).to include('"@context":"https://schema.org"')
      expect(json_ld).to include('"@id":"https://develoz.com/#org"')
      expect(json_ld).to include('"@id":"https://develoz.com/#service"')
    end
  end
end
