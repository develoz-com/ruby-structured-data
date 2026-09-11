# frozen_string_literal: true

require "date"
require "time"

RSpec.describe StructuredData::Validator do
  let(:validator) { described_class.new }
  let(:valid_person) { StructuredData::Node.new(:Person, name: "Alice", email: "alice@example.com") }

  describe ".validate and #validate" do
    it "validates a clean Node as valid with 0 errors" do
      result = described_class.validate(valid_person)
      expect(result).to be_valid
      expect(result.errors).to be_empty
      expect(result.warnings).to be_empty
    end

    it "supports class method with custom vocabulary" do
      custom_data = { "types" => { "CustomWidget" => { "parents" => ["Thing"] } } }
      custom_vocab = StructuredData::Vocabulary.new(custom_data)
      node = StructuredData::Node.new("CustomWidget")
      result = described_class.validate(node, vocabulary: custom_vocab)
      expect(result).to be_valid
    end

    it "raises ArgumentError when target is not a Node or Document" do
      expect { validator.validate("invalid target") }.to raise_error(
        ArgumentError, /Target must be a StructuredData::Node or StructuredData::Document/
      )
    end

    it "raises ArgumentError when mode is invalid" do
      expect { validator.validate(valid_person, mode: :invalid_mode) }.to raise_error(
        ArgumentError, /Invalid validation mode: :invalid_mode/
      )
    end

    it "returns an empty valid result when mode is :none" do
      invalid_node = StructuredData::Node.new("UnknownNonexistentType", invalid_attr: 123)
      result = validator.validate(invalid_node, mode: :none)
      expect(result).to be_valid
      expect(result.diagnostics).to be_empty
    end
  end

  describe "type validation" do
    it "reports :unknown_type with a DidYouMean suggestion" do
      node = StructuredData::Node.new("Preson")
      result = validator.validate(node)
      expect(result.errors.size).to eq(1)
      diagnostic = result.errors.first
      expect(diagnostic.code).to eq(:unknown_type)
      expect(diagnostic.suggestion).to eq("Person")
    end

    it "reports :unknown_type without a suggestion when no match is found" do
      node = StructuredData::Node.new("ZzzXxxYyy999")
      result = validator.validate(node)
      diagnostic = result.errors.first
      expect(diagnostic.code).to eq(:unknown_type)
      expect(diagnostic.suggestion).to be_nil
    end

    it "reports :superseded_term warning in schema_org mode for superseded type" do
      node = StructuredData::Node.new("Code")
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :superseded_term }
      expect(diagnostic.suggestion).to eq("SoftwareSourceCode")
      expect(result).to be_valid
    end

    it "reports :superseded_term error in strict mode for superseded type" do
      node = StructuredData::Node.new("Code")
      result = validator.validate(node, mode: :strict)
      diagnostic = result.errors.find { |d| d.code == :superseded_term }
      expect(diagnostic.severity).to eq(:error)
      expect(result).not_to be_valid
    end

    it "reports superseded term without unknown type when type is superseded but not in types" do
      node = StructuredData::Node.new("Dermatologic")
      result = validator.validate(node)
      expect(result.warnings.find { |d| d.code == :superseded_term }).not_to be_nil
      expect(result.errors.find { |d| d.code == :unknown_type }).to be_nil
    end
  end

  describe "property name validation" do
    it "reports :unknown_property with DidYouMean suggestion" do
      node = StructuredData::Node.new(:Person, nmae: "Alice")
      result = validator.validate(node)
      diagnostic = result.errors.first
      expect(diagnostic.code).to eq(:unknown_property)
      expect(diagnostic.path).to eq("$.nmae")
      expect(diagnostic.suggestion).to eq("name")
    end

    it "reports :unknown_property without suggestion when no close term exists" do
      node = StructuredData::Node.new(:Person, zzzzz_unknown_prop: "val")
      result = validator.validate(node)
      diagnostic = result.errors.first
      expect(diagnostic.code).to eq(:unknown_property)
      expect(diagnostic.suggestion).to be_nil
    end

    it "reports :superseded_term warning in schema_org mode for superseded property" do
      node = StructuredData::Node.new(:CreativeWork, aspect: "main")
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :superseded_term }
      expect(diagnostic.suggestion).to eq("mainContentOfPage")
      expect(diagnostic.severity).to eq(:warning)
    end

    it "reports :superseded_term error in strict mode for superseded property" do
      node = StructuredData::Node.new(:CreativeWork, aspect: "main")
      result = validator.validate(node, mode: :strict)
      diagnostic = result.errors.find { |d| d.code == :superseded_term }
      expect(diagnostic.severity).to eq(:error)
    end

    it "reports superseded property without unknown property when not in properties" do
      custom_data = {
        "types" => { "CustomItem" => { "parents" => ["Thing"] } },
        "superseded" => { "oldProp" => "newProp" }
      }
      custom_vocab = StructuredData::Vocabulary.new(custom_data)
      node = StructuredData::Node.new("CustomItem", old_prop: "val")
      result = described_class.validate(node, vocabulary: custom_vocab)
      expect(result.warnings.find { |d| d.code == :superseded_term }).not_to be_nil
      expect(result.errors.find { |d| d.code == :unknown_property }).to be_nil
    end
  end

  describe "domain mismatch validation" do
    it "reports :domain_mismatch warning in schema_org mode" do
      node = StructuredData::Node.new(:Book, total_payment_due: 100)
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :domain_mismatch }
      expect(diagnostic.severity).to eq(:warning)
      expect(result).to be_valid
    end

    it "reports :domain_mismatch error in strict mode" do
      node = StructuredData::Node.new(:Book, total_payment_due: 100)
      result = validator.validate(node, mode: :strict)
      diagnostic = result.errors.find { |d| d.code == :domain_mismatch }
      expect(diagnostic.severity).to eq(:error)
      expect(result).not_to be_valid
    end
  end

  describe "range mismatch validation" do
    it "reports :range_mismatch when Node type is not in expected ranges" do
      node = StructuredData::Node.new(:CreativeWork, author: StructuredData::Node.new(:Book))
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :range_mismatch }
      expect(diagnostic.path).to eq("$.author")
      expect(diagnostic.severity).to eq(:warning)
    end

    it "reports :range_mismatch error in strict mode for Node type mismatch" do
      node = StructuredData::Node.new(:CreativeWork, author: StructuredData::Node.new(:Book))
      result = validator.validate(node, mode: :strict)
      diagnostic = result.errors.find { |d| d.code == :range_mismatch }
      expect(diagnostic.severity).to eq(:error)
    end

    it "reports :range_mismatch when primitive type does not match Boolean range" do
      node = StructuredData::Node.new(:CreativeWork, is_accessible_for_free: 123)
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :range_mismatch }
      expect(diagnostic.path).to eq("$.isAccessibleForFree")
    end

    it "reports :range_mismatch when primitive type does not match Number range" do
      node = StructuredData::Node.new(:Invoice, total_payment_due: true)
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :range_mismatch }
      expect(diagnostic.path).to eq("$.totalPaymentDue")
    end

    it "reports :range_mismatch when String is passed for an entity-only range" do
      node = StructuredData::Node.new(:CreativeWork, author: 123)
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :range_mismatch }
      expect(diagnostic.path).to eq("$.author")
    end

    it "accepts valid primitive and wrapper values for compatible ranges" do
      node = StructuredData::Node.new(
        :Person,
        name: "Alice",
        url: StructuredData::Values.url("https://example.com"),
        birth_date: Date.today.to_s
      )
      result = validator.validate(node)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "accepts Reference, Enum, Text, and DateTime objects when ranges match" do
      node = StructuredData::Node.new(
        :CreativeWork,
        author: StructuredData::Reference.new("https://example.com/org"),
        encoding_format: StructuredData::Values.text("text/html"),
        date_published: DateTime.now.iso8601
      )
      result = validator.validate(node)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "accepts real Date and Time objects for Date/Time properties" do
      node = StructuredData::Node.new(
        :Event,
        name: "Conf",
        start_date: Date.today,
        end_date: Time.now
      )
      result = validator.validate(node)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "validates Enum values against enum ranges and text ranges" do
      in_stock = StructuredData::Enum.new(:InStock, :ItemAvailability)
      offer = StructuredData::Node.new(:Offer, availability: in_stock, name: StructuredData::Enum.new(:InStock))
      result = validator.validate(offer)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "validates untyped Enum on an enum-only range" do
      untyped_enum = StructuredData::Enum.new(:InStock)
      offer = StructuredData::Node.new(:Offer, availability: untyped_enum)
      result = validator.validate(offer)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "reports range mismatch for Enum with mismatched type" do
      bad_type_enum = StructuredData::Enum.new(:InStock, :ItemAvailability)
      creative_work = StructuredData::Node.new(:CreativeWork, author: bad_type_enum)
      result = validator.validate(creative_work)
      expect(result.warnings.find { |d| d.code == :range_mismatch }).not_to be_nil
    end

    it "reports range mismatch for invalid Enum value" do
      bad_enum = StructuredData::Enum.new(:BadStock, :ItemAvailability)
      offer = StructuredData::Node.new(:Offer, availability: bad_enum)
      result = validator.validate(offer)
      expect(result.warnings.find { |d| d.code == :range_mismatch }).not_to be_nil
    end

    it "validates string values matching enum members" do
      offer = StructuredData::Node.new(:Offer, availability: "InStock")
      result = validator.validate(offer)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "reports range mismatch when string is not a valid enum member" do
      offer = StructuredData::Node.new(:Offer, availability: "TotallyInvalidMember")
      result = validator.validate(offer)
      expect(result.warnings.find { |d| d.code == :range_mismatch }).not_to be_nil
    end

    it "reports range mismatch for unsupported object type" do
      node = StructuredData::Node.new(:Person, name: :symbol_not_allowed)
      result = validator.validate(node)
      expect(result.warnings.find { |d| d.code == :range_mismatch }).not_to be_nil
    end

    it "accepts Node whose ancestor matches expected range" do
      svc = StructuredData::Node.new(:ProfessionalService, name: "Consulting")
      node = StructuredData::Node.new(:Organization, sub_organization: svc)
      result = validator.validate(node)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "accepts any Node when property range includes Thing" do
      custom_data = {
        "types" => { "ThingContainer" => { "parents" => ["Thing"] } },
        "properties" => { "anyItem" => { "domains" => ["ThingContainer"], "ranges" => ["Thing"] } }
      }
      custom_vocab = StructuredData::Vocabulary.new(custom_data)
      node = StructuredData::Node.new("ThingContainer", any_item: StructuredData::Node.new(:Person, name: "Bob"))
      result = described_class.validate(node, vocabulary: custom_vocab)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end

    it "accepts any value when property has empty expected ranges" do
      custom_data = {
        "types" => { "FlexItem" => { "parents" => ["Thing"] } },
        "properties" => { "anything" => { "domains" => ["FlexItem"], "ranges" => [] } }
      }
      custom_vocab = StructuredData::Vocabulary.new(custom_data)
      node = StructuredData::Node.new("FlexItem", anything: "whatever")
      result = described_class.validate(node, vocabulary: custom_vocab)
      expect(result.warnings.select { |d| d.code == :range_mismatch }).to be_empty
    end
  end

  describe "nested node, array, and list validation" do
    it "recursively validates nested nodes" do
      invalid_address = StructuredData::Node.new(:PostalAddress, invalid_prop: "bad")
      org = StructuredData::Node.new(:Organization, name: "Acme", address: invalid_address)
      result = validator.validate(org)
      diagnostic = result.errors.first
      expect(diagnostic.path).to eq("$.address.invalidProp")
      expect(diagnostic.code).to eq(:unknown_property)
    end

    it "recursively validates nodes within arrays" do
      item1 = StructuredData::Node.new(:Person, name: "Valid")
      item2 = StructuredData::Node.new(:Person, wrnog_attr: 1)
      node = StructuredData::Node.new(:ItemList, item_list_element: [item1, item2])
      result = validator.validate(node)
      diagnostic = result.errors.first
      expect(diagnostic.path).to eq("$.itemListElement[1].wrnogAttr")
    end

    it "recursively validates nodes within a StructuredData::List" do
      item = StructuredData::Node.new(:Person, badd_key: "oops")
      list = StructuredData::List.new([item])
      node = StructuredData::Node.new(:ItemList, item_list_element: list)
      result = validator.validate(node)
      diagnostic = result.errors.first
      expect(diagnostic.path).to eq("$.itemListElement.@list[0].baddKey")
    end

    it "reports range mismatch for invalid primitive element inside array" do
      node = StructuredData::Node.new(:CreativeWork, keywords: ["tech", true])
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :range_mismatch }
      expect(diagnostic.path).to eq("$.keywords[1]")
    end

    it "reports range mismatch for invalid primitive element inside list" do
      node = StructuredData::Node.new(:CreativeWork, keywords: StructuredData::List.new(["tech", 999]))
      result = validator.validate(node)
      diagnostic = result.warnings.find { |d| d.code == :range_mismatch }
      expect(diagnostic.path).to eq("$.keywords.@list[1]")
    end
  end

  describe "document validation" do
    it "validates a single-node document with root path $" do
      doc = StructuredData::Document.new(StructuredData::Node.new(:Person, wrng: "1"))
      result = validator.validate(doc)
      expect(result.errors.first.path).to eq("$.wrng")
    end

    it "validates a multi-node document with $.@graph[idx] paths" do
      node1 = StructuredData::Node.new(:Person, name: "Alice")
      node2 = StructuredData::Node.new(:Person, wrng: "Bob")
      doc = StructuredData::Document.new(node1, node2)
      result = validator.validate(doc)
      expect(result.errors.first.path).to eq("$.@graph[1].wrng")
    end

    it "validates an empty document as valid" do
      doc = StructuredData::Document.new
      result = validator.validate(doc)
      expect(result).to be_valid
    end
  end

  describe "#validate! and .validate!" do
    it "returns the ValidationResult when target is valid" do
      result = validator.validate!(valid_person)
      expect(result).to be_a(StructuredData::Validator::Result)
      expect(result).to be_valid
    end

    it "raises StructuredData::ValidationError when invalid in instance method" do
      bad_node = StructuredData::Node.new(:Person, bad_prop: "test")
      expect { validator.validate!(bad_node) }.to raise_error(StructuredData::ValidationError) do |error|
        expect(error.result).to be_a(StructuredData::Validator::Result)
        expect(error.message).to include("$.badProp: Unknown property 'badProp' for type 'Person'")
      end
    end

    it "raises StructuredData::ValidationError when invalid in class method" do
      bad_node = StructuredData::Node.new(:Person, bad_prop: "test")
      expect { described_class.validate!(bad_node) }.to raise_error(StructuredData::ValidationError)
    end

    it "allows instantiating ValidationError with custom string" do
      error = StructuredData::ValidationError.new("Custom message")
      expect(error.message).to eq("Custom message")
      expect(error.result).to be_nil
    end
  end

  describe "Diagnostic and Result value equality and methods" do
    it "implements error?, warning?, and to_h on Diagnostic" do
      diag = StructuredData::Validator::Diagnostic.new(
        code: :unknown_type, severity: :error, path: "$.@type", message: "Err", suggestion: "Type"
      )
      expect(diag).to be_error
      expect(diag).not_to be_warning
      expect(diag.to_h).to be_a(Hash)
    end

    it "implements == and hash on Diagnostic" do
      diag1 = StructuredData::Validator::Diagnostic.new(
        code: :unknown_type, severity: :error, path: "$.@type", message: "Err", suggestion: "Type"
      )
      diag2 = StructuredData::Validator::Diagnostic.new(
        code: :unknown_type, severity: :error, path: "$.@type", message: "Err", suggestion: "Type"
      )
      expect(diag1 == diag2).to be true
      expect(diag1.hash).to eq(diag2.hash)
    end

    it "implements == and hash on Result" do
      res1 = StructuredData::Validator::Result.new
      res2 = StructuredData::Validator::Result.new
      expect(res1 == res2).to be true
      expect(res1.hash).to eq(res2.hash)
    end
  end
end
