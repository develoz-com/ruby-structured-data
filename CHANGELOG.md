# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Rails integration loads automatically from the default `gem "ruby-structured-data"` require. The Railtie registers when Rails is present; framework-only usage requires no extra setup.

## [0.1.0] - 2026-09-11

### Added

- Framework-neutral core Schema.org JSON-LD authoring DSL (`StructuredData.node`, `StructuredData.document`, `StructuredData.ref`, `StructuredData.list`, `StructuredData.enum`, `StructuredData.url`, `StructuredData.text`).
- Embedded Schema.org vocabulary definition supporting types, properties, multiple inheritance, domain/range metadata, and enumerations.
- Offline metadata-driven validator supporting `:schema_org`, `:strict`, and `:none` validation modes with DidYouMean suggestions and superseded term detection.
- Fast, HTML-safe JSON-LD serialization neutralizing `</script>` tags and unicode line/paragraph separators.
- Vocabulary compiler CLI / Rake task (`bundle exec rake vocabulary:update`) to build vocabulary data from upstream Schema.org JSON-LD definitions.
- Optional Rails integration:
  - `StructuredData::Rails::Railtie` configuring Railtie options and view helper loading.
  - `StructuredData::Rails::Registry` for mapping controller/action endpoints to structured data builders.
  - `StructuredData::Rails::Renderer` for generating `ActiveSupport::SafeBuffer` JSON-LD `<script>` tags.
  - `StructuredData::Rails::Helper#structured_data_tag` for view rendering.
  - `rails generate structured_data:install` generator creating `config/initializers/structured_data.rb`.
- GitHub Actions CI workflow with Ruby 3.4 matrix, RuboCop, Reek, Bundler Audit, and 100% line/branch RSpec coverage.
- GitHub Actions Release workflow publishing gems to RubyGems.
