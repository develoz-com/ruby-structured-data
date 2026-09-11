# frozen_string_literal: true

require "rails/generators/base"

module StructuredData
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Copies StructuredData initializer to your application."

      def copy_initializer
        copy_file "structured_data.rb", "config/initializers/structured_data.rb"
      end
    end
  end
end
