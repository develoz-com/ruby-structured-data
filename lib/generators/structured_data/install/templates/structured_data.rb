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
