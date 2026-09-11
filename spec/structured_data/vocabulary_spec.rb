# frozen_string_literal: true

require "pathname"

RSpec.describe StructuredData::Vocabulary do
  let(:vocabulary) { described_class.new }

  describe ".default and .reset!" do
    after { described_class.reset! }

    it "returns a singleton instance" do
      expect(described_class.default).to be_a(described_class)
      expect(described_class.default).to equal(described_class.default)
    end

    it "resets the singleton instance" do
      initial = described_class.default
      described_class.reset!
      expect(described_class.default).not_to equal(initial)
    end
  end

  describe "class method delegation" do
    after { described_class.reset! }

    it "delegates type queries to .default" do
      expect(described_class.type_defined?("Event")).to be true
      expect(described_class.type_info("Event")).to be_a(Hash)
      expect(described_class.ancestors("SportsEvent")).to include("Event")
    end

    it "delegates property queries to .default" do
      expect(described_class.property_defined?("startDate")).to be true
      expect(described_class.property_info("startDate")).to be_a(Hash)
      expect(described_class.property_allowed_for?("Event", "startDate")).to be true
    end

    it "delegates ranges, enums, superseded, and registration to .default" do
      expect(described_class.expected_ranges("sport")).to eq(%w[Text URL])
      expect(described_class.enum_type?("ItemAvailability")).to be true
      expect(described_class.enum_member?("ItemAvailability", "InStock")).to be true
    end

    it "delegates superseded and registration" do
      expect(described_class.superseded_by("Code")).to eq("SoftwareSourceCode")
      custom_data = { types: { "Widget" => { parents: ["Thing"] } } }
      described_class.register_vocabulary("widget", custom_data)
      expect(described_class.type_defined?("Widget")).to be true
    end

    it "delegates all_types and all_properties" do
      custom_data = { types: { "Widget" => { parents: ["Thing"] } } }
      described_class.register_vocabulary("widget", custom_data)
      expect(described_class.all_types).to include("Person", "Widget")
      expect(described_class.all_properties).to include("name", "url")
    end
  end

  describe "#initialize and source loading" do
    it "loads default data when source is nil" do
      expect(vocabulary.type_defined?("Thing")).to be true
    end

    it "loads data from a Hash" do
      custom_hash = { "types" => { "Custom" => { "parents" => [] } } }
      custom_vocab = described_class.new(custom_hash)
      expect(custom_vocab.type_defined?("Custom")).to be true
      expect(custom_vocab.type_defined?("Thing")).to be false
    end

    it "returns empty arrays for all_types and all_properties when data lacks types and properties" do
      empty_vocab = described_class.new({})
      expect(empty_vocab.all_types).to eq([])
      expect(empty_vocab.all_properties).to eq([])
    end

    it "loads data from a file path string" do
      path = File.expand_path("../../data/schema_org_v30.json", __dir__)
      custom_vocab = described_class.new(path)
      expect(custom_vocab.type_defined?("Thing")).to be true
    end

    it "loads data from a Pathname" do
      pathname = Pathname.new(File.expand_path("../../data/schema_org_v30.json", __dir__))
      custom_vocab = described_class.new(pathname)
      expect(custom_vocab.type_defined?("Thing")).to be true
    end

    it "raises ArgumentError for invalid source types" do
      expect { described_class.new(12_345) }
        .to raise_error(ArgumentError, /Invalid vocabulary source/)
    end
  end

  describe "#type_defined? and #type_info" do
    it "returns true for defined core types" do
      expect(vocabulary.type_defined?("SportsEvent")).to be true
      expect(vocabulary.type_defined?(:SportsEvent)).to be true
    end

    it "handles Schema.org URIs" do
      expect(vocabulary.type_defined?("https://schema.org/SportsEvent")).to be true
    end

    it "returns false for unknown types, nil, or empty strings" do
      expect(vocabulary.type_defined?("NonExistentType")).to be false
      expect(vocabulary.type_defined?(nil)).to be false
      expect(vocabulary.type_defined?("")).to be false
    end

    it "returns type information hash for defined types" do
      info = vocabulary.type_info("SportsEvent")
      expect(info).to be_a(Hash)
      expect(info["parents"]).to eq(["Event"])
    end

    it "returns nil for undefined types" do
      expect(vocabulary.type_info("MissingType")).to be_nil
      expect(vocabulary.type_info(nil)).to be_nil
    end
  end

  describe "#ancestors" do
    it "returns transitive ancestors for single inheritance" do
      expect(vocabulary.ancestors("SportsEvent")).to eq(%w[Event Thing])
    end

    it "returns transitive ancestors for multiple inheritance" do
      expect(vocabulary.ancestors("LocalBusiness")).to eq(%w[Organization Place Thing])
    end

    it "returns empty array for root types or unknown types" do
      expect(vocabulary.ancestors("Thing")).to eq([])
      expect(vocabulary.ancestors("UnknownType")).to eq([])
      expect(vocabulary.ancestors("")).to eq([])
    end

    it "handles circular inheritance safely without infinite loops" do
      circular_data = {
        "types" => {
          "TypeA" => { "parents" => ["TypeB"] },
          "TypeB" => { "parents" => ["TypeA"] }
        }
      }
      circ_vocab = described_class.new(circular_data)
      expect(circ_vocab.ancestors("TypeA")).to eq(%w[TypeB])
    end

    it "handles diamond inheritance without duplicate ancestors" do
      diamond_data = {
        "types" => {
          "Top" => { "parents" => [] },
          "Left" => { "parents" => ["Top"] },
          "Right" => { "parents" => ["Top"] },
          "Bottom" => { "parents" => %w[Left Right] }
        }
      }
      diamond_vocab = described_class.new(diamond_data)
      expect(diamond_vocab.ancestors("Bottom")).to eq(%w[Left Right Top])
    end
  end

  describe "#property_defined? and #property_info" do
    it "checks if properties are defined" do
      expect(vocabulary.property_defined?("startDate")).to be true
      expect(vocabulary.property_defined?(:startDate)).to be true
      expect(vocabulary.property_defined?("unknownProp")).to be false
    end

    it "returns property info hash or nil" do
      info = vocabulary.property_info("sport")
      expect(info["domains"]).to include("SportsEvent")
      expect(vocabulary.property_info("unknownProp")).to be_nil
      expect(vocabulary.property_info(nil)).to be_nil
    end
  end

  describe "#property_allowed_for?" do
    it "returns true when property domain matches type directly" do
      expect(vocabulary.property_allowed_for?("SportsEvent", "sport")).to be true
      expect(vocabulary.property_allowed_for?(:SportsEvent, :sport)).to be true
    end

    it "returns true when property domain matches an ancestor type" do
      expect(vocabulary.property_allowed_for?("SportsEvent", "startDate")).to be true
      expect(vocabulary.property_allowed_for?("SportsEvent", "name")).to be true
    end

    it "returns false when property is not allowed for the type" do
      expect(vocabulary.property_allowed_for?("SportsEvent", "slogan")).to be false
    end

    it "returns false when property or type does not exist" do
      expect(vocabulary.property_allowed_for?("SportsEvent", "missingProp")).to be false
      expect(vocabulary.property_allowed_for?("MissingType", "sport")).to be false
    end
  end

  describe "#expected_ranges" do
    it "returns range types array for a valid property" do
      expect(vocabulary.expected_ranges("sport")).to eq(%w[Text URL])
    end

    it "returns empty array for an unknown property" do
      expect(vocabulary.expected_ranges("unknownProperty")).to eq([])
    end
  end

  describe "#enum_type? and #enum_member?" do
    it "identifies enumeration types" do
      expect(vocabulary.enum_type?("ItemAvailability")).to be true
      expect(vocabulary.enum_type?("Enumeration")).to be true
      expect(vocabulary.enum_type?("QualitativeValue")).to be true
    end

    it "returns false for non-enum types, nil, or empty strings" do
      expect(vocabulary.enum_type?("SportsEvent")).to be false
      expect(vocabulary.enum_type?(nil)).to be false
      expect(vocabulary.enum_type?("")).to be false
    end

    it "validates enum members directly and via symbols" do
      expect(vocabulary.enum_member?("ItemAvailability", "InStock")).to be true
      expect(vocabulary.enum_member?(:ItemAvailability, :InStock)).to be true
      expect(vocabulary.enum_member?("ItemAvailability", "InvalidMember")).to be false
    end

    it "normalizes enum member URIs and Enum objects" do
      uri = "https://schema.org/InStock"
      enum_obj = StructuredData::Enum.new("InStock")
      expect(vocabulary.enum_member?("ItemAvailability", uri)).to be true
      expect(vocabulary.enum_member?("ItemAvailability", enum_obj)).to be true
    end

    it "returns false for unknown enums, nil, or empty member names" do
      expect(vocabulary.enum_member?("MissingEnum", "InStock")).to be false
      expect(vocabulary.enum_member?("ItemAvailability", nil)).to be false
      expect(vocabulary.enum_member?("", "InStock")).to be false
    end

    it "validates inherited enum members from ancestor enums" do
      expect(vocabulary.enum_member?("WearableSizeSystemEnumeration", "SizeSystemMetric")).to be true
    end
  end

  describe "#superseded_by" do
    it "returns the replacing term for superseded terms" do
      expect(vocabulary.superseded_by("Code")).to eq("SoftwareSourceCode")
      expect(vocabulary.superseded_by(:Code)).to eq("SoftwareSourceCode")
    end

    it "returns nil for non-superseded terms or empty input" do
      expect(vocabulary.superseded_by("Thing")).to be_nil
      expect(vocabulary.superseded_by(nil)).to be_nil
      expect(vocabulary.superseded_by("")).to be_nil
    end
  end

  describe "#register_vocabulary" do
    let(:custom_data) do
      {
        types: {
          "Gene" => { parents: ["Thing"] }
        },
        properties: {
          "dnaSequence" => { domains: ["Gene"], ranges: ["Text"] }
        },
        enums: {
          "StrandType" => %w[Forward Reverse]
        },
        superseded: {
          "oldSequence" => "dnaSequence"
        }
      }
    end

    it "registers custom types, properties, enums, and superseded terms" do
      result = vocabulary.register_vocabulary("bio", custom_data)
      expect(result).to equal(vocabulary)
      expect(vocabulary.type_defined?("Gene")).to be true
      expect(vocabulary.type_defined?("bio:Gene")).to be true
    end

    it "resolves ancestors and property permissions for custom types" do
      vocabulary.register_vocabulary("bio", custom_data)
      expect(vocabulary.ancestors("Gene")).to eq(["Thing"])
      expect(vocabulary.property_allowed_for?("Gene", "dnaSequence")).to be true
      expect(vocabulary.property_allowed_for?("Gene", "name")).to be true
    end

    it "resolves custom enums and superseded mappings" do
      vocabulary.register_vocabulary("bio", custom_data)
      expect(vocabulary.enum_type?("StrandType")).to be true
      expect(vocabulary.enum_member?("StrandType", "Forward")).to be true
      expect(vocabulary.superseded_by("oldSequence")).to eq("dnaSequence")
    end

    it "handles missing entries and prefixes in custom vocabularies" do
      vocabulary.register_vocabulary("bio", custom_data)
      expect(vocabulary.type_info("unknown_prefix:Gene")).to be_nil
      expect(vocabulary.type_info("bio:MissingLocal")).to be_nil
    end

    it "handles non-hash values, enums with Enum instances, and nil terms during registration" do
      weird_data = {
        types: { "Simple" => "string_description" },
        enums: { "CustomEnum" => [StructuredData::Enum.new("EVal"), nil] },
        superseded: { nil => "replacement" }
      }
      expect { vocabulary.register_vocabulary("weird", weird_data) }.not_to raise_error
      expect(vocabulary.type_info("Simple")).to eq("string_description")
    end

    it "raises ArgumentError when registered data is not a Hash" do
      expect { vocabulary.register_vocabulary("bio", "not a hash") }
        .to raise_error(ArgumentError, /must be a Hash/)
    end
  end
end
