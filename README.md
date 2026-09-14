# Ruby Structured Data (`ruby-structured-data`)

Framework-neutral Ruby gem for authoring, validating, and rendering [Schema.org](https://schema.org) JSON-LD structured data with metadata-driven validation and seamless Rails integration.

## Features

- **Fluent DSL**: Expressive API for authoring nodes, documents, graphs, enums, lists, and references.
- **Embedded Schema.org Vocabulary**: Built-in vocabulary supporting Schema.org types, properties, inheritance, and enumerations.
- **Diagnostics & Validation**: Fast, metadata-driven validation with three modes (`:schema_org`, `:strict`, `:none`) featuring DidYouMean suggestions and superseded term checks.
- **XSS-Safe Serialization**: HTML-safe JSON-LD serialization neutralizing `</script>` breakouts and unicode line/paragraph separators.
- **Rails Integration**: View helper (`structured_data_tag`), page builder registry (`StructuredData::Rails::Registry`), Railtie configuration, and generator (`rails generate structured_data:install`).
- **100% Test Coverage**: Full line and branch test coverage enforced via SimpleCov.

---

## Installation

Add the gem to your application's `Gemfile`:

```ruby
gem "ruby-structured-data"
```

Then execute:

```bash
bundle install
```

Or install it directly:

```bash
gem install ruby-structured-data
```

---

## Quickstart

### Authoring Nodes

Create Schema.org entities using `StructuredData.node`:

```ruby
require "ruby-structured-data"

person = StructuredData.node("Person",
  id: "https://example.com/people/alice",
  name: "Alice Smith",
  job_title: "Software Engineer",
  url: "https://example.com/alice"
)

# You can also use a block for structured composition:
organization = StructuredData.node("Organization", id: "https://example.com/#org") do |org|
  org.set(:name, "Acme Corp")
  org.set(:url, "https://example.com")
  org.set(:founder, person)
end
```

### Documents & Graphs

Wrap nodes in a `StructuredData.document`. By default, a document with a single node renders as a single entity with `@context`. Multiple nodes or documents explicitly initialized with `graph: true` render within an `@graph` array:

```ruby
# Single entity document
doc = StructuredData.document(organization)
puts StructuredData.dump(doc, pretty: true)
# => {
#      "@context": "https://schema.org",
#      "@type": "Organization",
#      "@id": "https://example.com/#org",
#      "name": "Acme Corp",
#      "url": "https://example.com",
#      "founder": {
#        "@type": "Person",
#        ...
#      }
#    }

# Explicit @graph document
graph_doc = StructuredData.document(organization, person, graph: true)
puts StructuredData.dump(graph_doc, pretty: true)
# => {
#      "@context": "https://schema.org",
#      "@graph": [
#        { "@type": "Organization", ... },
#        { "@type": "Person", ... }
#      ]
#    }
```

### Value Helpers

- `StructuredData.ref("https://example.com/people/alice")`: Creates an entity reference (`{ "@id": "..." }`).
- `StructuredData.list("Item 1", "Item 2")`: Wraps ordered items in an `@list`.
- `StructuredData.enum("InStock", "ItemAvailability")`: Generates a Schema.org enumeration URI.
- `StructuredData.url("https://example.com")`: Validated URL wrapper.
- `StructuredData.text("Sample text")`: Text value wrapper.

---

## Schema.org Validation

`StructuredData.validate` validates nodes or documents against Schema.org metadata without making network requests.

### Modes

- `:schema_org` (default): Checks unknown types/properties, warns on superseded terms, and flags incompatible ranges.
- `:strict`: Treats warnings as errors (such as domain mismatches or superseded terms).
- `:none`: Bypasses schema validation.

```ruby
# Validating a node
result = StructuredData.validate(person, mode: :schema_org)

if result.valid?
  puts "Valid Schema.org data!"
else
  result.errors.each { |err| puts "[ERROR] #{err.message}" }
  result.warnings.each { |warn| puts "[WARNING] #{warn.message}" }
end

# Or raise a ValidationError when invalid:
StructuredData.validate!(person)
```

---

## Rails Integration

### 1. Install Generator

Run the generator to install the initializer:

```bash
bin/rails generate structured_data:install
```

This creates `config/initializers/structured_data.rb`:

```ruby
# frozen_string_literal: true

StructuredData.configure do |config|
  # Validation mode: :strict, :schema_org (default), or :none
  config.validation_mode = :schema_org

  # Output pretty formatted JSON-LD
  config.pretty = Rails.env.development?
end

# Register controller/action structured data builders:
# StructuredData::Rails::Registry.register("landing#index", LandingPageBuilder)
# StructuredData::Rails::Registry.register("products#show") do |context|
#   StructuredData.node("Product", name: context.product.name)
# end
```

### 2. Registry & Builders

Register structured data builders for specific controller actions:

```ruby
# Using a block
StructuredData::Rails::Registry.register("products#show") do |view_context|
  product = view_context.assigns["product"]
  StructuredData.node("Product",
    name: product.name,
    description: product.description,
    sku: product.sku
  )
end

# Or using a dedicated builder class
class LandingPageBuilder
  def self.build(view_context)
    StructuredData.document(
      StructuredData.node("WebSite",
        name: "Acme",
        url: "https://example.com"
      )
    )
  end
end

StructuredData::Rails::Registry.register("landing#index", LandingPageBuilder)
```

### 3. View Helper (`structured_data_tag`)

Render the JSON-LD script tag in your layout or view template (e.g. `app/views/layouts/application.html.erb`):

```erb
<head>
  <%= structured_data_tag %>
</head>
```

When called without arguments, `structured_data_tag` automatically looks up the registered builder matching `controller_path#action_name`.

You can also pass an explicit node or document:

```erb
<%= structured_data_tag(@article_schema) %>
```

Output is marked `html_safe` and wrapped in:

```html
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"Product","name":"Widget"}
</script>
```

---

## Updating Vocabulary

The embedded vocabulary definitions can be re-compiled from upstream Schema.org releases using the compiler:

```bash
bundle exec rake schemaorg:update
```

---

## Development

Clone the repository and install dependencies:

```bash
git clone https://github.com/develoz-com/ruby-structured-data.git
cd ruby-structured-data
bundle install
```

Run test suite and quality checks:

```bash
bundle exec rspec    # Run test suite
bundle exec rubocop  # Run RuboCop linter
bundle exec reek     # Run Reek code smell detector
bin/ci               # Run complete CI pipeline (RuboCop, Reek, RSpec, Bundler Audit)
```

---

## License

This project is available as open source under the terms of the [MIT License](LICENSE.txt).
