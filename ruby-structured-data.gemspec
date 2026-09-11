# frozen_string_literal: true

require_relative "lib/structured_data/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-structured-data"
  spec.version = StructuredData::VERSION
  spec.authors = ["Mauricio Zaffari"]
  spec.email = ["mauriciozaffari@gmail.com"]

  spec.summary = "Schema.org JSON-LD authoring and structured data DSL for Ruby."
  spec.description = "Framework-neutral Ruby gem for authoring Schema.org JSON-LD structured data with metadata-driven validation and optional Rails integration."
  spec.homepage = "https://github.com/develoz-com/ruby-structured-data"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["{data,lib}/**/*", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |file| File.basename(file) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "actionpack", ">= 7.0"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "railties", ">= 7.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "reek", "~> 6.3"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.65"
  spec.add_development_dependency "rubocop-performance", "~> 1.21"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rubycw", "~> 0.1.6"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-lcov", "~> 0.8"
end
