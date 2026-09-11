# frozen_string_literal: true

require "rails"
require "structured_data/rails/registry"

RSpec.describe StructuredData::Rails::Registry do
  before { described_class.clear! }

  after { described_class.clear! }

  describe ".register and .registered?" do
    it "registers a builder with target string" do
      builder = -> { StructuredData.node("Person", name: "Alice") }
      described_class.register("landing#index", builder)

      expect(described_class.registered?("landing#index")).to be true
      expect(described_class.registered?("landing", "index")).to be true
    end

    it "registers with block" do
      described_class.register("landing#index") do
        StructuredData.node("Person", name: "Bob")
      end

      expect(described_class.registered?("landing#index")).to be true
    end

    it "registers with controller, action, and builder args" do
      builder = -> { StructuredData.node("Person", name: "Charlie") }
      described_class.register(:users, :show, builder)

      expect(described_class.registered?(:users, :show)).to be true
      expect(described_class.registered?("users#show")).to be true
    end

    it "registers with controller, action, and block" do
      described_class.register(:users, :edit) do
        StructuredData.node("Person", name: "David")
      end

      expect(described_class.registered?("users#edit")).to be true
    end

    it "normalizes keys with leading slashes" do
      builder = -> { StructuredData.node("Person", name: "Eve") }
      described_class.register("/admin/dashboard#show", builder)

      expect(described_class.registered?("admin/dashboard#show")).to be true
      expect(described_class.registered?("/admin/dashboard", "show")).to be true
    end

    it "returns false for unregistered targets" do
      expect(described_class.registered?("unknown#action")).to be false
    end
  end

  describe ".clear! and .reset!" do
    it "clears all registered builders" do
      described_class.register("landing#index", -> {})
      described_class.clear!

      expect(described_class.registered?("landing#index")).to be false
    end

    it "supports .reset! alias" do
      described_class.register("landing#index", -> {})
      described_class.reset!

      expect(described_class.registered?("landing#index")).to be false
    end
  end

  describe ".resolve" do
    it "returns nil when key is not registered" do
      expect(described_class.resolve("missing", "index")).to be_nil
    end

    it "returns static value when builder is a pre-built node" do
      node = StructuredData.node("Person", name: "Static")
      described_class.register("landing#index", node)

      expect(described_class.resolve("landing", "index")).to eq(node)
    end

    context "with callable builders" do
      it "resolves arity-0 callables without passing context" do
        described_class.register("landing#index", -> { StructuredData.node("Person", name: "Zero") })
        result = described_class.resolve("landing", "index")

        expect(result[:name]).to eq("Zero")
      end

      it "resolves arity-1 callables passing context" do
        described_class.register("landing#index", ->(ctx) { StructuredData.node("Person", name: ctx[:name]) })
        result = described_class.resolve("landing", "index", { name: "ContextUser" })

        expect(result[:name]).to eq("ContextUser")
      end
    end

    context "with object builders implementing #build" do
      it "calls #build without arguments when arity is zero" do
        builder = Class.new do
          def build
            StructuredData.node("Person", name: "ZeroArityBuild")
          end
        end.new

        described_class.register("landing#index", builder)
        result = described_class.resolve("landing", "index")

        expect(result[:name]).to eq("ZeroArityBuild")
      end

      it "calls #build with context when arity is non-zero" do
        builder = Class.new do
          def build(ctx)
            StructuredData.node("Person", name: ctx[:user_name])
          end
        end.new

        described_class.register("landing#index", builder)
        result = described_class.resolve("landing", "index", { user_name: "ParamBuild" })

        expect(result[:name]).to eq("ParamBuild")
      end
    end

    context "with class builders" do
      it "calls class-level .build with context" do
        klass = Class.new do
          def self.build(ctx)
            StructuredData.node("Person", name: ctx[:title])
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index", { title: "ClassBuild" })

        expect(result[:name]).to eq("ClassBuild")
      end

      it "calls class-level .build without context when arity is 0" do
        klass = Class.new do
          def self.build
            StructuredData.node("Person", name: "ClassBuildZero")
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index")

        expect(result[:name]).to eq("ClassBuildZero")
      end

      it "calls class-level .call with context" do
        klass = Class.new do
          def self.call(ctx)
            StructuredData.node("Person", name: ctx[:title])
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index", { title: "ClassCall" })

        expect(result[:name]).to eq("ClassCall")
      end

      it "calls class-level .call without context when arity is 0" do
        klass = Class.new do
          def self.call
            StructuredData.node("Person", name: "ClassCallZero")
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index")

        expect(result[:name]).to eq("ClassCallZero")
      end

      it "instantiates arity-0 initializer and calls #build with context" do
        klass = Class.new do
          def build(ctx)
            StructuredData.node("Person", name: ctx[:title])
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index", { title: "InstBuildWithCtx" })

        expect(result[:name]).to eq("InstBuildWithCtx")
      end

      it "instantiates arity-0 initializer and calls #build with 0 args" do
        klass = Class.new do
          def build
            StructuredData.node("Person", name: "InstBuildZero")
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index")

        expect(result[:name]).to eq("InstBuildZero")
      end

      it "instantiates arity-0 initializer and calls #call with context" do
        klass = Class.new do
          def call(ctx)
            StructuredData.node("Person", name: ctx[:title])
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index", { title: "InstCallWithCtx" })

        expect(result[:name]).to eq("InstCallWithCtx")
      end

      it "instantiates arity-0 initializer and calls #call with 0 args" do
        klass = Class.new do
          def call
            StructuredData.node("Person", name: "InstCallZero")
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index")

        expect(result[:name]).to eq("InstCallZero")
      end

      it "instantiates arity-0 initializer and returns instance when no build/call" do
        klass = Class.new
        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index")

        expect(result).to be_a(klass)
      end

      it "instantiates arity-1 initializer passing context and calls #build" do
        klass = Class.new do
          def initialize(ctx)
            @ctx = ctx
          end

          def build
            StructuredData.node("Person", name: @ctx[:title])
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index", { title: "InitCtxBuild" })

        expect(result[:name]).to eq("InitCtxBuild")
      end

      it "instantiates arity-1 initializer passing context and calls #call" do
        klass = Class.new do
          def initialize(ctx)
            @ctx = ctx
          end

          def call
            StructuredData.node("Person", name: @ctx[:title])
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index", { title: "InitCtxCall" })

        expect(result[:name]).to eq("InitCtxCall")
      end

      it "instantiates arity-1 initializer and returns instance when no build/call" do
        klass = Class.new do
          attr_reader :ctx

          def initialize(ctx)
            @ctx = ctx
          end
        end

        described_class.register("landing#index", klass)
        result = described_class.resolve("landing", "index", { title: "NoBuildCall" })

        expect(result.ctx).to eq({ title: "NoBuildCall" })
      end
    end

    it "operates safely under multithreaded concurrent registrations" do
      threads = Array.new(10) do |idx|
        Thread.new do
          described_class.register("controller#{idx}#index", -> { idx })
          expect(described_class.resolve("controller#{idx}", "index")).to eq(idx)
        end
      end
      threads.each(&:join)
    end
  end
end
