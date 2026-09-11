# frozen_string_literal: true

RSpec.describe StructuredData::List do
  describe "#initialize" do
    it "accepts an array of items" do
      list = described_class.new(%w[step1 step2])
      expect(list.items).to eq(%w[step1 step2])
    end

    it "accepts any Enumerable source and converts to array" do
      list = described_class.new(Set.new(%w[a b]))
      expect(list.items).to contain_exactly("a", "b")
    end

    it "defaults to an empty array when no argument is given" do
      list = described_class.new
      expect(list.items).to eq([])
    end

    it "raises ArgumentError when items is not Enumerable" do
      expect { described_class.new(12_345) }
        .to raise_error(ArgumentError, /items must be Enumerable/)
    end
  end

  describe "#each" do
    it "iterates through items" do
      list = described_class.new(%w[first second])
      expect { |probe| list.each(&probe) }.to yield_successive_args("first", "second")
    end
  end

  describe "#to_h" do
    it "serializes simple primitive items under @list" do
      list = described_class.new([1, "two", 3.0])
      expect(list.to_h).to eq({ "@list" => [1, "two", 3.0] })
    end

    it "converts items responding to to_h" do
      item1 = instance_double(StructuredData::Reference, to_h: { "@id" => "https://example.com/1" })
      list = described_class.new([item1, "raw"])
      expect(list.to_h).to eq({ "@list" => [{ "@id" => "https://example.com/1" }, "raw"] })
    end

    it "recursively converts nested arrays within items" do
      list = described_class.new([%w[nested array], "top"])
      expect(list.to_h).to eq({ "@list" => [%w[nested array], "top"] })
    end
  end

  describe "equality" do
    let(:first_list) { described_class.new(%w[a b]) }
    let(:identical_list) { described_class.new(%w[a b]) }
    let(:different_list) { described_class.new(%w[c d]) }

    it "considers lists with same items equal via ==" do
      expect(first_list).to eq(identical_list)
      expect(first_list).not_to eq(different_list)
    end

    it "returns false when comparing == to another class" do
      expect(first_list == %w[a b]).to be(false)
    end

    it "considers lists with same items equal via eql?" do
      expect(first_list.eql?(identical_list)).to be(true)
      expect(first_list.eql?(different_list)).to be(false)
    end

    it "produces matching hash values for equal lists" do
      expect(first_list.hash).to eq(identical_list.hash)
      expect(first_list.hash).not_to eq(different_list.hash)
    end
  end
end
