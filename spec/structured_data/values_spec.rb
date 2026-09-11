# frozen_string_literal: true

RSpec.describe StructuredData::Values do
  describe ".url" do
    it "wraps a valid string URL into a Url value object" do
      url = described_class.url("https://schema.org/Person")
      expect(url).to be_a(StructuredData::Values::Url)
      expect(url.to_s).to eq("https://schema.org/Person")
      expect(url.to_h).to eq("https://schema.org/Person")
    end

    it "accepts a URI::Generic object" do
      uri = URI("https://example.com/logo.png")
      url = described_class.url(uri)
      expect(url.value).to eq("https://example.com/logo.png")
    end

    it "returns the same instance if already a Url object" do
      url1 = described_class.url("https://schema.org")
      url2 = described_class.url(url1)
      expect(url2).to be(url1)
    end

    it "serializes correctly to JSON via as_json and to_json" do
      url = described_class.url("https://example.com")
      expect(url.as_json).to eq("https://example.com")
      expect(url.to_json).to eq("\"https://example.com\"")
      expect(url.to_str).to eq("https://example.com")
    end

    it "raises ArgumentError for blank URL inputs" do
      expect { described_class.url(nil) }
        .to raise_error(ArgumentError, /URL cannot be blank/)
      expect { described_class.url("   ") }
        .to raise_error(ArgumentError, /URL cannot be blank/)
    end

    it "raises ArgumentError when scheme is missing" do
      expect { described_class.url("not-a-url") }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end

    it "raises ArgumentError when host and path are missing" do
      expect { described_class.url("http://") }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end

    it "raises ArgumentError on invalid URI syntax" do
      allow(URI).to receive(:parse).and_raise(URI::InvalidURIError.new("bad uri"))
      expect { described_class.url("http://bad-uri.com") }
        .to raise_error(ArgumentError, /bad uri/)
    end

    describe "Url equality" do
      let(:example_url) { described_class.url("https://example.com") }
      let(:matching_url) { described_class.url("https://example.com") }
      let(:different_url) { described_class.url("https://other.com") }

      it "implements == with Url objects and strings" do
        expect(example_url).to eq(matching_url)
        expect(example_url).to eq("https://example.com")
        expect(example_url).not_to eq(different_url)
      end

      it "returns false when comparing == to incompatible objects" do
        expect(example_url == 42).to be(false)
      end

      it "implements eql? and hash" do
        expect(example_url.eql?(matching_url)).to be(true)
        expect(example_url.eql?(different_url)).to be(false)
        expect(example_url.hash).to eq(matching_url.hash)
      end
    end
  end

  describe ".text" do
    it "wraps a string into a Text value object" do
      text = described_class.text("Hello World")
      expect(text).to be_a(StructuredData::Values::Text)
      expect(text.to_s).to eq("Hello World")
      expect(text.to_h).to eq("Hello World")
    end

    it "converts numbers to string representation" do
      text = described_class.text(12_345)
      expect(text.value).to eq("12345")
    end

    it "returns the same instance if already a Text object" do
      original_text = described_class.text("sample")
      wrapped_again = described_class.text(original_text)
      expect(wrapped_again).to be(original_text)
    end

    it "serializes correctly to JSON via as_json and to_json" do
      text = described_class.text("abc")
      expect(text.as_json).to eq("abc")
      expect(text.to_json).to eq("\"abc\"")
      expect(text.to_str).to eq("abc")
    end

    it "raises ArgumentError when input is nil" do
      expect { described_class.text(nil) }
        .to raise_error(ArgumentError, /Text cannot be nil/)
    end

    describe "Text equality" do
      let(:greeting_text) { described_class.text("hello") }
      let(:matching_text) { described_class.text("hello") }
      let(:different_text) { described_class.text("world") }

      it "implements == with Text objects and strings" do
        expect(greeting_text).to eq(matching_text)
        expect(greeting_text).to eq("hello")
        expect(greeting_text).not_to eq(different_text)
      end

      it "returns false when comparing == to incompatible objects" do
        expect(greeting_text == 123).to be(false)
      end

      it "implements eql? and hash" do
        expect(greeting_text.eql?(matching_text)).to be(true)
        expect(greeting_text.eql?(different_text)).to be(false)
        expect(greeting_text.hash).to eq(matching_text.hash)
      end
    end
  end

  describe ".ref" do
    it "creates a Reference instance" do
      ref = described_class.ref("https://schema.org/Person")
      expect(ref).to be_a(StructuredData::Reference)
      expect(ref.id).to eq("https://schema.org/Person")
    end
  end

  describe ".list" do
    it "creates a List instance from variable arguments" do
      list = described_class.list("item1", "item2")
      expect(list).to be_a(StructuredData::List)
      expect(list.items).to eq(%w[item1 item2])
    end

    it "flattens array arguments" do
      list = described_class.list([%w[a b], "c"])
      expect(list.items).to eq(%w[a b c])
    end
  end

  describe ".enum" do
    it "creates an Enum instance with name and optional type" do
      enum = described_class.enum(:InStock, :ItemAvailability)
      expect(enum).to be_a(StructuredData::Enum)
      expect(enum.name).to eq("InStock")
      expect(enum.type).to eq("ItemAvailability")
    end
  end
end
