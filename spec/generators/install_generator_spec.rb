# frozen_string_literal: true

require "tmpdir"
require "rails/generators"
require "generators/structured_data/install/install_generator"

RSpec.describe "StructuredData::Generators::InstallGenerator" do
  let(:generator_class) { StructuredData::Generators::InstallGenerator }

  it "subclasses Rails::Generators::Base" do
    expect(generator_class.superclass).to eq(Rails::Generators::Base)
  end

  it "copies the initializer template to config/initializers/structured_data.rb" do
    Dir.mktmpdir do |dir|
      generator = generator_class.new([], {}, destination_root: dir)
      expect { generator.copy_initializer }.to output(%r{create\s+config/initializers/structured_data\.rb}).to_stdout

      target_path = File.join(dir, "config/initializers/structured_data.rb")
      expect(File.exist?(target_path)).to be true

      content = File.read(target_path)
      expect(content).to include("StructuredData.configure").and include("StructuredData::Rails::Registry.register")
    end
  end
end
