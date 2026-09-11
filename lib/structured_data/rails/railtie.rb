# frozen_string_literal: true

module StructuredData
  module Rails
    class Railtie < ::Rails::Railtie
      config.structured_data = ActiveSupport::OrderedOptions.new

      initializer "structured_data.setup" do |app|
        options = app.config.structured_data

        StructuredData.configure do |config|
          config.validation_mode = options.validation_mode unless options.validation_mode.nil?
          config.pretty = options.pretty unless options.pretty.nil?
        end

        ActiveSupport.on_load(:action_view) do
          include StructuredData::Rails::Helper
        end
      end
    end
  end
end
