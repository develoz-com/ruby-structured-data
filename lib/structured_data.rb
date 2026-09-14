# frozen_string_literal: true

require_relative "structured_data/version"
require_relative "structured_data/error"
require_relative "structured_data/configuration"
require_relative "structured_data/compiler"
require_relative "structured_data/reference"
require_relative "structured_data/list"
require_relative "structured_data/enum"
require_relative "structured_data/values"
require_relative "structured_data/node"
require_relative "structured_data/vocabulary"
require_relative "structured_data/document"
require_relative "structured_data/validator"
require_relative "structured_data/serializer"

# Rails integration is optional: StructuredData::Rails::Railtie subclasses
# ::Rails::Railtie, so requiring it without Rails raises NameError.
begin
  require_relative "structured_data/rails"
rescue LoadError, NameError
  nil
end

module StructuredData
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config) if block_given?
      config
    end

    def reset_config!
      @config = Configuration.new
    end

    def node(type, id: nil, **attributes, &)
      Node.new(type, id: id, **attributes, &)
    end

    def document(*nodes, **)
      Document.new(*nodes, **)
    end

    def ref(id)
      Reference.new(id)
    end

    def list(*items)
      Values.list(*items)
    end

    def enum(name, type = nil)
      Values.enum(name, type)
    end

    def url(val)
      Values.url(val)
    end

    def text(val)
      Values.text(val)
    end

    def validate(target, mode: config.validation_mode)
      Validator.validate(target, mode: mode)
    end

    def validate!(target, mode: config.validation_mode)
      Validator.validate!(target, mode: mode)
    end

    def dump(target, pretty: config.pretty)
      Serializer.dump(target, pretty: pretty)
    end

    def vocabulary
      Vocabulary.default
    end
  end
end
