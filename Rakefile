# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run RuboCop linter"
task :rubocop do
  sh "bundle exec rubocop"
end

desc "Run Reek code smell detector"
task :reek do
  sh "bundle exec reek"
end

desc "Run CI checks"
task :ci do
  sh "bin/ci"
end

SCHEMAORG_KEY_TYPES = %w[
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
].freeze

def download_schemaorg(url, limit = 5)
  raise "HTTP redirect limit exceeded" if limit <= 0

  response = Net::HTTP.get_response(URI(url))
  case response
  when Net::HTTPSuccess
    response.body
  when Net::HTTPRedirection
    download_schemaorg(response["location"], limit - 1)
  else
    abort "Failed to download #{url}: #{response.code} #{response.message}"
  end
end

namespace :schemaorg do
  desc "Download and compile Schema.org N-Triples vocabulary (default version: 30.0)"
  task :update, [:version] do |_t, args|
    require "net/http"
    require "tempfile"
    require "uri"
    require_relative "lib/structured_data"

    version = args[:version] || "30.0"
    tag = version.start_with?("v") ? version : "v#{version}"
    release = tag.delete_prefix("v")
    url = "https://raw.githubusercontent.com/schemaorg/schemaorg/#{tag}/data/releases/#{release}/schemaorg-current-https.nt"
    target_dir = File.expand_path("data", __dir__)
    FileUtils.mkdir_p(target_dir)

    major_minor = release.sub(/\.0$/, "")
    target_path = File.join(target_dir, "schema_org_v#{major_minor}.json")

    puts "Downloading #{url}..."
    content = download_schemaorg(url)

    Tempfile.create(["schemaorg-", ".nt"]) do |temp_file|
      temp_file.write(content)
      temp_file.flush

      puts "Compiling to #{target_path}..."
      StructuredData::Compiler.compile_to_file(temp_file.path, target_path, version: release)
      puts "Successfully compiled #{target_path} (#{File.size(target_path)} bytes)"
    end
  end

  desc "Verify compiled Schema.org vocabulary data"
  task :verify do
    require "json"

    data_file = File.expand_path("data/schema_org_v30.json", __dir__)
    abort "Error: #{data_file} does not exist" unless File.exist?(data_file)

    data = JSON.parse(File.read(data_file))
    abort "Error: Invalid version in #{data_file}" unless data["version"] == "30.0"

    missing = SCHEMAORG_KEY_TYPES.reject { |type| data.dig("types", type) }
    abort "Error: Missing key types in #{data_file}: #{missing.join(', ')}" if missing.any?

    puts "Schema.org v#{data['version']} verified: #{data['types'].size} types, #{data['properties'].size} properties"
  end
end

task default: :spec
