# frozen_string_literal: true

module StructuredData
  class Compiler
    module Terms
      PREDICATES = {
        subclass_of: "http://www.w3.org/2000/01/rdf-schema#subClassOf",
        type: "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
        domain_includes: "https://schema.org/domainIncludes",
        range_includes: "https://schema.org/rangeIncludes",
        superseded_by: "https://schema.org/supersededBy",
        is_part_of: "https://schema.org/isPartOf"
      }.freeze

      TYPES = {
        rdfs_class: "http://www.w3.org/2000/01/rdf-schema#Class",
        rdf_class: "http://www.w3.org/1999/02/22-rdf-syntax-ns#Class",
        rdf_property: "http://www.w3.org/1999/02/22-rdf-syntax-ns#Property"
      }.freeze

      SCHEMA_PREFIX = "https://schema.org/"
    end
  end
end
