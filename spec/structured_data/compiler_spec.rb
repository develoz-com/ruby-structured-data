# frozen_string_literal: true

require "pathname"
require "stringio"
require "tmpdir"

RSpec.describe StructuredData::Compiler do
  describe ".compile" do
    it "compiles classes with default parents and core section" do
      nt = "<https://schema.org/Thing> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n"
      result = described_class.compile(nt)

      expect(result["types"]["Thing"]).to eq({ "parents" => [], "section" => "core" })
    end

    it "compiles single inheritance and normalizes http to https" do
      nt = "<http://schema.org/Organization> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<http://schema.org/Organization> <http://www.w3.org/2000/01/rdf-schema#subClassOf> " \
           "<http://schema.org/Thing> .\n"
      result = described_class.compile(nt)

      expect(result["types"]["Organization"]["parents"]).to eq(["Thing"])
    end

    it "compiles multiple inheritance with sorted unique parents" do
      nt = "<https://schema.org/LocalBusiness> <http://www.w3.org/2000/01/rdf-schema#subClassOf> " \
           "<https://schema.org/Place> .\n" \
           "<https://schema.org/LocalBusiness> <http://www.w3.org/2000/01/rdf-schema#subClassOf> " \
           "<https://schema.org/Organization> .\n" \
           "<https://schema.org/LocalBusiness> <http://www.w3.org/2000/01/rdf-schema#subClassOf> " \
           "<https://schema.org/Place> .\n"
      result = described_class.compile(nt)

      expect(result["types"]["LocalBusiness"]["parents"]).to eq(%w[Organization Place])
    end

    it "compiles properties with multiple domains and ranges sorted" do
      nt = "<https://schema.org/name> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property> .\n" \
           "<https://schema.org/name> <https://schema.org/domainIncludes> <https://schema.org/Thing> .\n" \
           "<https://schema.org/name> <https://schema.org/domainIncludes> <https://schema.org/CreativeWork> .\n" \
           "<https://schema.org/name> <https://schema.org/rangeIncludes> <https://schema.org/Text> .\n"
      result = described_class.compile(nt)

      expect(result["properties"]["name"]).to eq(
        { "domains" => %w[CreativeWork Thing], "ranges" => ["Text"] }
      )
    end

    it "compiles enum instances under their enumeration class" do
      nt = "<https://schema.org/ItemAvailability> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<https://schema.org/InStock> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<https://schema.org/ItemAvailability> .\n" \
           "<https://schema.org/Discontinued> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<https://schema.org/ItemAvailability> .\n"
      result = described_class.compile(nt)

      expect(result["enums"]["ItemAvailability"]).to eq(%w[Discontinued InStock])
    end

    it "compiles superseded terms" do
      nt = "<https://schema.org/vendor> <https://schema.org/supersededBy> <https://schema.org/seller> .\n"
      result = described_class.compile(nt)

      expect(result["superseded"]).to eq({ "vendor" => "seller" })
    end

    it "compiles section from isPartOf subdomain and literal" do
      nt = "<https://schema.org/Hospital> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<https://schema.org/Hospital> <https://schema.org/isPartOf> <https://pending.schema.org> .\n" \
           "<https://schema.org/LegacyType> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<https://schema.org/LegacyType> <https://schema.org/isPartOf> \"attic\" .\n"
      result = described_class.compile(nt)

      expect(result["types"]["Hospital"]["section"]).to eq("pending")
      expect(result["types"]["LegacyType"]["section"]).to eq("attic")
    end

    it "handles version parameter" do
      result = described_class.compile("", version: "31.0")

      expect(result["version"]).to eq("31.0")
    end
  end

  describe "sources" do
    it "accepts an IO source like StringIO" do
      io = StringIO.new(
        "<https://schema.org/Person> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
        "<http://www.w3.org/2000/01/rdf-schema#Class> .\n"
      )
      result = described_class.compile(io)

      expect(result["types"]).to have_key("Person")
    end

    it "accepts a file path string source" do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, "schema.nt")
        File.write(file_path, "<https://schema.org/Book> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
                              "<http://www.w3.org/2000/01/rdf-schema#Class> .\n")
        result = described_class.compile(file_path)

        expect(result["types"]).to have_key("Book")
      end
    end

    it "accepts a Pathname source" do
      Dir.mktmpdir do |dir|
        file_path = Pathname.new(File.join(dir, "schema.nt"))
        File.write(file_path, "<https://schema.org/Event> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
                              "<http://www.w3.org/2000/01/rdf-schema#Class> .\n")
        result = described_class.compile(file_path)

        expect(result["types"]).to have_key("Event")
      end
    end

    it "raises ArgumentError for unsupported source type" do
      expect { described_class.compile(12_345) }.to raise_error(ArgumentError, /Unsupported source/)
    end
  end

  describe ".compile_to_file" do
    it "writes formatted JSON to target file and returns hash" do
      Dir.mktmpdir do |dir|
        source_path = File.join(dir, "source.nt")
        target_path = File.join(dir, "target.json")
        File.write(source_path, "<https://schema.org/Thing> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
                                "<http://www.w3.org/2000/01/rdf-schema#Class> .\n")

        result = described_class.compile_to_file(source_path, target_path, version: "30.0")

        expect(File.exist?(target_path)).to be(true)
        expect(JSON.parse(File.read(target_path))["types"]).to have_key("Thing")
        expect(result["types"]).to have_key("Thing")
      end
    end
  end

  describe "parsing edge cases" do
    it "ignores comments, blank lines, and trailing spaces" do
      nt = "   \n# Comment line\n  # Indented comment\n  " \
           "<https://schema.org/Thing> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .   # trailing comment\n\n"
      result = described_class.compile(nt)

      expect(result["types"].keys).to eq(["Thing"])
    end

    it "ignores blank nodes safely" do
      nt = "_:b0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://schema.org/Thing> .\n" \
           "<https://schema.org/Thing> <https://schema.org/item> _:b1 .\n"
      result = described_class.compile(nt)

      expect(result["types"]).to be_empty
    end

    it "ignores non-schema.org extraneous triples" do
      nt = "<http://example.com/foo> <http://example.com/bar> <http://example.com/baz> .\n" \
           "<https://schema.org/Thing> <http://www.w3.org/2000/01/rdf-schema#comment> \"A thing.\" .\n"
      result = described_class.compile(nt)

      expect(result["types"]).to be_empty
      expect(result["properties"]).to be_empty
    end

    it "unescapes backslash and unicode escapes in URIs and literals" do
      nt = "<https://schema.org/Escaped\\t\\b\\n\\r\\f\\\"\\'\\\\\\u0020\\U00000041> " \
           "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/1999/02/22-rdf-syntax-ns#Class> .\n"
      expect { described_class.compile(nt) }.not_to raise_error
    end

    it "raises ParseError for malformed syntax" do
      invalid_line = "<https://schema.org/Thing> invalid_pred"
      expect { described_class.compile(invalid_line) }.to raise_error(StructuredData::Compiler::ParseError) do |err|
        expect(err.line_number).to eq(1)
        expect(err.line).to eq(invalid_line)
      end
    end
  end

  describe "additional edge cases and branch coverage" do
    it "recognizes rdf:Class as class type" do
      nt = "<https://schema.org/Item> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/1999/02/22-rdf-syntax-ns#Class> .\n"
      result = described_class.compile(nt)

      expect(result["types"]).to have_key("Item")
    end

    it "ignores non-schema parent in subClassOf" do
      nt = "<https://schema.org/Item> <http://www.w3.org/2000/01/rdf-schema#subClassOf> " \
           "<http://www.w3.org/2000/01/rdf-schema#Resource> .\n"
      result = described_class.compile(nt)

      expect(result["types"]["Item"]["parents"]).to eq([])
    end

    it "ignores non-schema domain or range" do
      nt = "<https://schema.org/itemProp> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property> .\n" \
           "<https://schema.org/itemProp> <https://schema.org/domainIncludes> <http://example.com/External> .\n" \
           "<https://schema.org/itemProp> <https://schema.org/rangeIncludes> <http://example.com/External> .\n"
      result = described_class.compile(nt)

      expect(result["properties"]["itemProp"]).to eq({ "domains" => [], "ranges" => [] })
    end

    it "ignores non-schema supersededBy" do
      nt = "<https://schema.org/oldProp> <https://schema.org/supersededBy> <http://example.com/newProp> .\n"
      result = described_class.compile(nt)

      expect(result["superseded"]).to be_empty
    end

    it "ignores non-schema rdf:type objects for enums" do
      nt = "<https://schema.org/Individual> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2002/07/owl#NamedIndividual> .\n"
      result = described_class.compile(nt)

      expect(result["enums"]).to be_empty
    end

    it "filters out enum members that are classes or properties" do
      nt = "<https://schema.org/Status> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<https://schema.org/Active> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<https://schema.org/Status> .\n" \
           "<https://schema.org/Active> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<https://schema.org/propMember> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<https://schema.org/Status> .\n" \
           "<https://schema.org/propMember> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/1999/02/22-rdf-syntax-ns#Property> .\n"
      result = described_class.compile(nt)

      expect(result["enums"]).not_to have_key("Status")
    end

    it "handles isPartOf with path and schema.org root" do
      nt = "<https://schema.org/TypeA> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<https://schema.org/TypeA> <https://schema.org/isPartOf> <https://schema.org/core> .\n" \
           "<https://schema.org/TypeB> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> " \
           "<http://www.w3.org/2000/01/rdf-schema#Class> .\n" \
           "<https://schema.org/TypeB> <https://schema.org/isPartOf> <https://www.schema.org> .\n"
      result = described_class.compile(nt)

      expect(result["types"]["TypeA"]["section"]).to eq("core")
      expect(result["types"]["TypeB"]["section"]).to eq("core")
    end

    it "ignores rdf:type with literal object" do
      nt = "<https://schema.org/Thing> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> \"LiteralType\" .\n"
      result = described_class.compile(nt)

      expect(result["types"]).to be_empty
    end
  end
end
