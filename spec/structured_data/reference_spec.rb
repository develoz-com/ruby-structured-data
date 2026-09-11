# frozen_string_literal: true

RSpec.describe StructuredData::Reference do
  describe "#initialize" do
    it "accepts a non-empty string id" do
      ref = described_class.new("https://schema.org/Person")
      expect(ref.id).to eq("https://schema.org/Person")
    end

    it "accepts a URI id" do
      uri = URI("https://schema.org/Person")
      ref = described_class.new(uri)
      expect(ref.id).to eq(uri)
    end

    it "raises ArgumentError when id is nil" do
      expect { described_class.new(nil) }
        .to raise_error(ArgumentError, /id cannot be blank/)
    end

    it "raises ArgumentError when id is an empty string" do
      expect { described_class.new("") }
        .to raise_error(ArgumentError, /id cannot be blank/)
    end

    it "raises ArgumentError when id is whitespace only" do
      expect { described_class.new("   ") }
        .to raise_error(ArgumentError, /id cannot be blank/)
    end

    it "raises ArgumentError when id is a blank URI" do
      expect { described_class.new(URI("")) }
        .to raise_error(ArgumentError, /id cannot be blank/)
    end

    it "raises ArgumentError when id is neither String nor URI" do
      expect { described_class.new(12_345) }
        .to raise_error(ArgumentError, /id must be a String or URI/)
    end
  end

  describe "#to_h" do
    it "returns hash with @id as string from string id" do
      ref = described_class.new("https://example.com/org/1")
      expect(ref.to_h).to eq({ "@id" => "https://example.com/org/1" })
    end

    it "returns hash with @id as string from URI id" do
      ref = described_class.new(URI("https://example.com/org/1"))
      expect(ref.to_h).to eq({ "@id" => "https://example.com/org/1" })
    end
  end

  describe "#to_s" do
    it "returns id as string" do
      ref = described_class.new(URI("https://example.com/org/1"))
      expect(ref.to_s).to eq("https://example.com/org/1")
    end
  end

  describe "equality" do
    let(:string_ref) { described_class.new("https://example.com/org/1") }
    let(:uri_ref) { described_class.new(URI("https://example.com/org/1")) }
    let(:different_ref) { described_class.new("https://example.com/org/2") }

    it "considers references with same string representation equal via ==" do
      expect(string_ref).to eq(uri_ref)
      expect(string_ref).not_to eq(different_ref)
    end

    it "returns false when comparing == to a different class" do
      expect(string_ref == "https://example.com/org/1").to be(false)
    end

    it "considers references with same string representation equal via eql?" do
      expect(string_ref.eql?(uri_ref)).to be(true)
      expect(string_ref.eql?(different_ref)).to be(false)
    end

    it "produces identical hash for equivalent references" do
      expect(string_ref.hash).to eq(uri_ref.hash)
      expect(string_ref.hash).not_to eq(different_ref.hash)
    end
  end
end
