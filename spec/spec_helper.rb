# frozen_string_literal: true

require "simplecov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.single_report_path = "coverage/lcov.info"
end

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ]
)

SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
  track_files "lib/**/*.rb"
  add_filter "/spec/"
  add_filter "/templates/"
end

if defined?(StructuredData::VERSION)
  StructuredData.class_eval { remove_const(:VERSION) }
  $LOADED_FEATURES.delete_if { |path| path.end_with?("structured_data/version.rb") }
end

require "rspec"
require "structured_data"
require "ruby_structured_data"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
end
