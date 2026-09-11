# frozen_string_literal: true

RSpec.describe StructuredData::Enum do
  describe "#initialize" do
    it "accepts a symbol name" do
      enum = described_class.new(:InStock)
      expect(enum.name).to eq("InStock")
      expect(enum.uri).to eq("https://schema.org/InStock")
    end

    it "accepts a string name and optional type" do
      enum = described_class.new("InStock", :ItemAvailability)
      expect(enum.name).to eq("InStock")
      expect(enum.type).to eq("ItemAvailability")
    end

    it "strips schema.org prefix from name and type" do
      enum = described_class.new("https://schema.org/InStock", "https://schema.org/ItemAvailability")
      expect(enum.name).to eq("InStock")
      expect(enum.type).to eq("ItemAvailability")
    end

    it "sets type to nil when type is blank" do
      enum = described_class.new(:InStock, "  ")
      expect(enum.type).to be_nil
    end

    it "raises ArgumentError when name is nil" do
      expect { described_class.new(nil) }
        .to raise_error(ArgumentError, /name cannot be blank/)
    end

    it "raises ArgumentError when name is empty" do
      expect { described_class.new("") }
        .to raise_error(ArgumentError, /name cannot be blank/)
    end

    it "raises ArgumentError when name is whitespace" do
      expect { described_class.new("   ") }
        .to raise_error(ArgumentError, /name cannot be blank/)
    end
  end

  describe "serialization methods" do
    let(:enum) { described_class.new(:InStock) }

    it "returns the URI for to_s and to_str" do
      expect(enum.to_s).to eq("https://schema.org/InStock")
      expect(enum.to_str).to eq("https://schema.org/InStock")
    end

    it "returns the URI for to_h and as_json" do
      expect(enum.to_h).to eq("https://schema.org/InStock")
      expect(enum.as_json).to eq("https://schema.org/InStock")
    end

    it "produces valid JSON string via to_json" do
      expect(enum.to_json).to eq("\"https://schema.org/InStock\"")
    end
  end

  describe "equality" do
    let(:in_stock_sym) { described_class.new(:InStock) }
    let(:in_stock_str) { described_class.new("InStock") }
    let(:discontinued_enum) { described_class.new(:Discontinued) }

    it "considers enums with same URI equal via ==" do
      expect(in_stock_sym).to eq(in_stock_str)
      expect(in_stock_sym).not_to eq(discontinued_enum)
    end

    it "compares equal to a matching string URI via ==" do
      expect(in_stock_sym).to eq("https://schema.org/InStock")
      expect(in_stock_sym).not_to eq("https://schema.org/Discontinued")
    end

    it "returns false when comparing == to an incompatible type" do
      expect(in_stock_sym == 12_345).to be(false)
    end

    it "considers enums with same URI equal via eql?" do
      expect(in_stock_sym.eql?(in_stock_str)).to be(true)
      expect(in_stock_sym.eql?(discontinued_enum)).to be(false)
    end

    it "produces identical hash values for equivalent enums" do
      expect(in_stock_sym.hash).to eq(in_stock_str.hash)
      expect(in_stock_sym.hash).not_to eq(discontinued_enum.hash)
    end
  end
end
