# frozen_string_literal: true

require "rails"
require "action_view"
require "structured_data/rails/helper"
require "structured_data/rails/railtie"

RSpec.describe StructuredData::Rails::Railtie do
  after { StructuredData.reset_config! }

  it "subclasses Rails::Railtie" do
    expect(described_class.superclass).to eq(Rails::Railtie)
  end

  it "configures config.structured_data as an OrderedOptions object" do
    expect(described_class.config.structured_data).to be_a(ActiveSupport::OrderedOptions)
  end

  describe "initializer 'structured_data.setup'" do
    let(:initializer) do
      described_class.initializers.find { |init| init.name == "structured_data.setup" }
    end

    it "syncs validation_mode and pretty to StructuredData.config" do
      app = Struct.new(:config).new(
        Struct.new(:structured_data).new(ActiveSupport::OrderedOptions.new)
      )
      app.config.structured_data.validation_mode = :strict
      app.config.structured_data.pretty = true

      initializer.run(app)

      expect(StructuredData.config.validation_mode).to eq(:strict)
      expect(StructuredData.config.pretty).to be true
    end

    it "leaves defaults when options are not set" do
      app = Struct.new(:config).new(
        Struct.new(:structured_data).new(ActiveSupport::OrderedOptions.new)
      )

      initializer.run(app)

      expect(StructuredData.config.validation_mode).to eq(:schema_org)
      expect(StructuredData.config.pretty).to be false
    end

    it "includes Helper in ActionView::Base via load hook" do
      app = Struct.new(:config).new(
        Struct.new(:structured_data).new(ActiveSupport::OrderedOptions.new)
      )

      initializer.run(app)

      expect(ActionView::Base.ancestors).to include(StructuredData::Rails::Helper)
    end
  end
end
