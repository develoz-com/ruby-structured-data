# frozen_string_literal: true

require "monitor"

module StructuredData
  module Rails
    class Registry
      @entries = {}
      @monitor = Monitor.new

      class << self
        def register(target_or_controller, action_or_builder = nil, builder = nil, &block)
          key, actual_builder = normalize_registration(
            target_or_controller, action_or_builder, builder, block
          )

          @monitor.synchronize do
            @entries[key] = actual_builder
          end
        end

        def resolve(controller_path, action_name, context = nil)
          key = normalize_key("#{controller_path}##{action_name}")
          builder = @monitor.synchronize { @entries[key] }
          return nil if builder.nil?

          execute(builder, context)
        end

        def clear!
          @monitor.synchronize do
            @entries.clear
          end
        end
        alias reset! clear!

        def registered?(target_or_controller, action = nil)
          key = if action
                  normalize_key("#{target_or_controller}##{action}")
                else
                  normalize_key(target_or_controller)
                end
          @monitor.synchronize { @entries.key?(key) }
        end

        private

        def normalize_registration(target, action_or_builder, builder, block)
          if block
            key = action_or_builder ? normalize_key("#{target}##{action_or_builder}") : normalize_key(target)
            [key, block]
          elsif builder
            [normalize_key("#{target}##{action_or_builder}"), builder]
          else
            [normalize_key(target), action_or_builder]
          end
        end

        def normalize_key(key)
          key.to_s.sub(%r{\A/+}, "")
        end

        def execute(builder, context)
          if builder.is_a?(Class)
            execute_class(builder, context)
          elsif builder.respond_to?(:call)
            execute_callable(builder, context)
          elsif builder.respond_to?(:build)
            execute_object_build(builder, context)
          else
            builder
          end
        end

        def execute_class(klass, context)
          if klass.respond_to?(:build)
            invoke_method(klass.method(:build), context)
          elsif klass.respond_to?(:call)
            invoke_method(klass.method(:call), context)
          else
            instantiate_and_invoke(klass, context)
          end
        end

        def instantiate_and_invoke(klass, context)
          init_arity = klass.instance_method(:initialize).arity
          instance = init_arity.zero? ? klass.new : klass.new(context)

          if instance.respond_to?(:build)
            invoke_method(instance.method(:build), context)
          elsif instance.respond_to?(:call)
            invoke_method(instance.method(:call), context)
          else
            instance
          end
        end

        def execute_callable(callable, context)
          if callable.respond_to?(:arity) && callable.arity.zero?
            callable.call
          else
            callable.call(context)
          end
        end

        def execute_object_build(obj, context)
          if obj.method(:build).arity.zero?
            obj.build
          else
            obj.build(context)
          end
        end

        def invoke_method(method_obj, context)
          if method_obj.arity.zero?
            method_obj.call
          else
            method_obj.call(context)
          end
        end
      end
    end
  end
end
