# frozen_string_literal: true

module StructuredData
  module Rails
    module Helper
      def structured_data_tag(document_or_node = nil)
        return Renderer.render(document_or_node) if document_or_node

        ctrl_path = structured_data_controller_path
        act_name = structured_data_action_name
        return nil unless ctrl_path && act_name

        resolved = Registry.resolve(ctrl_path, act_name, self)
        return nil if resolved.nil?

        Renderer.render(resolved)
      end

      private

      def structured_data_controller_path
        if respond_to?(:controller_path) && controller_path
          controller_path
        elsif respond_to?(:controller) && controller.respond_to?(:controller_path)
          controller.controller_path
        end
      end

      def structured_data_action_name
        if respond_to?(:action_name) && action_name
          action_name
        elsif respond_to?(:controller) && controller.respond_to?(:action_name)
          controller.action_name
        end
      end
    end
  end
end
