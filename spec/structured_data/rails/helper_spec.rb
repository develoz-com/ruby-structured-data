# frozen_string_literal: true

require "rails"
require "active_support/core_ext/string/output_safety"
require "structured_data/rails/registry"
require "structured_data/rails/renderer"
require "structured_data/rails/helper"

RSpec.describe StructuredData::Rails::Helper do
  let(:helper_view) do
    Class.new do
      include StructuredData::Rails::Helper

      attr_accessor :controller_path, :action_name, :controller
    end.new
  end

  before { StructuredData::Rails::Registry.clear! }

  after { StructuredData::Rails::Registry.clear! }

  describe "#structured_data_tag" do
    it "renders explicit node argument directly" do
      node = StructuredData.node("Person", name: "Explicit")
      result = helper_view.structured_data_tag(node)

      expect(result).to be_a(ActiveSupport::SafeBuffer)
      expect(result).to include('"name":"Explicit"')
    end

    it "renders explicit document argument directly" do
      doc = StructuredData.document(StructuredData.node("Organization", name: "DocCo"))
      result = helper_view.structured_data_tag(doc)

      expect(result).to be_a(ActiveSupport::SafeBuffer)
      expect(result).to include('"name":"DocCo"')
    end

    context "when resolving from registry via view context methods" do
      it "renders registered builder using controller_path and action_name on self" do
        helper_view.controller_path = "products"
        helper_view.action_name = "show"

        StructuredData::Rails::Registry.register("products#show") do |ctx|
          StructuredData.node("Product", name: "Widget for #{ctx.action_name}")
        end

        result = helper_view.structured_data_tag
        expect(result).to be_a(ActiveSupport::SafeBuffer)
        expect(result).to include('"name":"Widget for show"')
      end

      it "returns nil when not registered in registry" do
        helper_view.controller_path = "products"
        helper_view.action_name = "index"

        expect(helper_view.structured_data_tag).to be_nil
      end

      it "returns nil when builder resolves to nil" do
        helper_view.controller_path = "products"
        helper_view.action_name = "edit"
        StructuredData::Rails::Registry.register("products#edit", ->(_ctx) {})

        expect(helper_view.structured_data_tag).to be_nil
      end
    end

    context "when resolving from registry via controller object" do
      let(:mock_controller) do
        Struct.new(:controller_path, :action_name).new("users", "profile")
      end

      it "delegates to controller.controller_path and controller.action_name" do
        helper_view.controller = mock_controller

        StructuredData::Rails::Registry.register("users#profile") do
          StructuredData.node("Person", name: "ProfileUser")
        end

        result = helper_view.structured_data_tag
        expect(result).to be_a(ActiveSupport::SafeBuffer)
        expect(result).to include('"name":"ProfileUser"')
      end

      it "returns nil when controller lacks controller_path" do
        helper_view.controller = Object.new
        expect(helper_view.structured_data_tag).to be_nil
      end

      it "returns nil when controller has controller_path but lacks action_name" do
        ctrl = Class.new do
          def controller_path
            "users"
          end
        end.new
        helper_view.controller = ctrl

        expect(helper_view.structured_data_tag).to be_nil
      end
    end

    context "when view context lacks controller metadata" do
      it "returns nil when neither self nor controller has controller_path" do
        expect(helper_view.structured_data_tag).to be_nil
      end

      it "returns nil when self has controller_path but lacks action_name" do
        helper_view.controller_path = "items"
        expect(helper_view.structured_data_tag).to be_nil
      end
    end
  end
end
