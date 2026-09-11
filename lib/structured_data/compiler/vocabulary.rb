# frozen_string_literal: true

module StructuredData
  class Compiler
    class Vocabulary
      CORE_SECTION = "core"

      def initialize(version)
        @version = version
        @data = {
          classes: Set.new,
          properties: Set.new,
          parents: {},
          domains: {},
          ranges: {},
          enums: {},
          superseded: {},
          sections: {}
        }
      end

      def add_class(name)
        @data[:classes].add(name)
      end

      def add_subclass(child, parent)
        @data[:classes].add(child)
        (@data[:parents][child] ||= []) << parent
      end

      def add_property(name)
        @data[:properties].add(name)
      end

      def add_domain(property, domain)
        @data[:properties].add(property)
        (@data[:domains][property] ||= []) << domain
      end

      def add_range(property, range)
        @data[:properties].add(property)
        (@data[:ranges][property] ||= []) << range
      end

      def add_enum_member(enum_type, member)
        (@data[:enums][enum_type] ||= []) << member
      end

      def add_superseded(old_term, new_term)
        @data[:superseded][old_term] = new_term
      end

      def set_section(term, section)
        @data[:sections][term] = section
      end

      def to_h
        {
          "version" => @version,
          "types" => build_types,
          "properties" => build_properties,
          "enums" => build_enums,
          "superseded" => build_superseded
        }
      end

      private

      def build_types
        @data[:classes].to_a.sort.to_h do |type_name|
          [
            type_name,
            {
              "parents" => (@data[:parents][type_name] || []).sort.uniq,
              "section" => @data[:sections][type_name] || CORE_SECTION
            }
          ]
        end
      end

      def build_properties
        @data[:properties].to_a.sort.to_h do |prop_name|
          [
            prop_name,
            {
              "domains" => (@data[:domains][prop_name] || []).sort.uniq,
              "ranges" => (@data[:ranges][prop_name] || []).sort.uniq
            }
          ]
        end
      end

      def build_enums
        result = {}
        @data[:enums].keys.sort.each do |enum_type|
          members = clean_enum_members(@data[:enums][enum_type])
          result[enum_type] = members unless members.empty?
        end
        result
      end

      def clean_enum_members(members)
        classes = @data[:classes]
        properties = @data[:properties]
        members.reject { |m| classes.include?(m) || properties.include?(m) }.sort.uniq
      end

      def build_superseded
        @data[:superseded].keys.sort.to_h do |term|
          [term, @data[:superseded][term]]
        end
      end
    end
  end
end
