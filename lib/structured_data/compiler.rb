# frozen_string_literal: true

require "json"
require_relative "compiler/vocabulary"
require_relative "compiler/parser"

module StructuredData
  class Compiler
    class ParseError < StandardError
      attr_reader :line_number, :line

      def initialize(message, line_number: nil, line: nil)
        @line_number = line_number
        @line = line
        super(message)
      end
    end

    class << self
      def compile(source, version: "30.0")
        new(source, version: version).compile
      end

      def compile_to_file(source_path, target_path, version: "30.0")
        new(source_path, version: version).compile_to_file(target_path)
      end
    end

    def initialize(source, version: "30.0")
      @source = source
      @version = version
    end

    def compile
      @compile ||= begin
        vocab = Vocabulary.new(@version)
        Parser.new(vocab).parse(source_lines)
        vocab.to_h
      end
    end

    def compile_to_file(target_path)
      result = compile
      File.write(target_path, "#{JSON.pretty_generate(result)}\n")
      result
    end

    private

    def source_lines
      if @source.respond_to?(:each_line) && !@source.is_a?(String)
        @source.each_line
      elsif @source.is_a?(String)
        string_source_lines
      else
        raise ArgumentError, "Unsupported source: #{@source.inspect}"
      end
    end

    def string_source_lines
      if !@source.include?("\n") && File.file?(@source)
        File.foreach(@source)
      else
        @source.each_line
      end
    end
  end
end
