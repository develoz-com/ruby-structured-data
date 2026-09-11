# frozen_string_literal: true

require "rails"
require "action_view"
require "structured_data/rails"

RSpec.describe StructuredData::Rails do
  it "defines the Rails integration module" do
    expect(described_class).to be_a(Module)
  end

  it "defines Registry and Renderer" do
    expect(described_class::Registry).to be_a(Class)
    expect(described_class::Renderer).to be_a(Class)
  end

  it "defines Helper and Railtie" do
    expect(described_class::Helper).to be_a(Module)
    expect(described_class::Railtie).to be_a(Class)
  end
end
