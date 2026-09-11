# frozen_string_literal: true

require "json"

RSpec.describe "StructuredData::VocabularyData" do
  let(:data_path) { File.expand_path("../../data/schema_org_v30.json", __dir__) }
  let(:raw_json) { File.read(data_path) }
  let(:data) { JSON.parse(raw_json) }

  describe "file structure and metadata" do
    it "exists on disk" do
      expect(File.exist?(data_path)).to be true
    end

    it "parses cleanly as valid JSON" do
      expect { JSON.parse(raw_json) }.not_to raise_error
    end

    it "has version 30.0" do
      expect(data["version"]).to eq("30.0")
    end
  end

  describe "presence of key types" do
    let(:key_types) do
      %w[
        Organization
        ProfessionalService
        Event
        SportsEvent
        Product
        PostalAddress
        Place
        WebSite
        BreadcrumbList
        Invoice
        EventReservation
        SoftwareApplication
      ]
    end

    it "contains all required project types" do
      expect(data["types"].keys).to include(*key_types)
    end
  end

  describe "inheritance relationships" do
    it "defines SportsEvent with parent Event" do
      expect(data.dig("types", "SportsEvent", "parents")).to eq(["Event"])
    end

    it "defines ProfessionalService with parent LocalBusiness" do
      expect(data.dig("types", "ProfessionalService", "parents")).to eq(["LocalBusiness"])
    end

    it "defines LocalBusiness with parents Organization and Place" do
      expect(data.dig("types", "LocalBusiness", "parents")).to eq(%w[Organization Place])
    end
  end

  describe "properties on expected domains" do
    it "includes slogan on Organization domain" do
      expect(data.dig("properties", "slogan", "domains")).to include("Organization")
    end

    it "includes name and url on Thing domain (inherited by Organization)" do
      expect(data.dig("properties", "name", "domains")).to include("Thing")
      expect(data.dig("properties", "url", "domains")).to include("Thing")
    end

    it "includes serviceType on Service domain" do
      expect(data.dig("properties", "serviceType", "domains")).to include("Service")
    end

    it "includes sport on SportsEvent domain" do
      expect(data.dig("properties", "sport", "domains")).to include("SportsEvent")
    end

    it "includes startDate and endDate on Event domain (inherited by SportsEvent)" do
      expect(data.dig("properties", "startDate", "domains")).to include("Event")
      expect(data.dig("properties", "endDate", "domains")).to include("Event")
    end

    it "includes totalPaymentDue on Invoice domain" do
      expect(data.dig("properties", "totalPaymentDue", "domains")).to include("Invoice")
    end

    it "associates reservation identifier with Reservation domain (inherited by EventReservation)" do
      prop = data["properties"]["reservationId"] || data["properties"]["reservationNumber"]
      expect(prop["domains"]).to include("Reservation")
    end
  end

  describe "enum members" do
    it "includes InStock in ItemAvailability" do
      expect(data.dig("enums", "ItemAvailability")).to include("InStock")
    end
  end
end
