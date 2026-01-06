#!/usr/bin/env ruby
# frozen_string_literal: true

# Load Dependabot Core as a library
$LOAD_PATH.unshift("/dependabot/dependabot-core/common/lib")
$LOAD_PATH.unshift("/dependabot/dependabot-core/npm_and_yarn/lib")
$LOAD_PATH.unshift("/dependabot/dependabot-core/updater/lib")
$LOAD_PATH.unshift("/dependabot/dependabot-core/core/lib")

require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/pull_request_creator"
require "dependabot/credential"

puts "== Dependabot Azure DevOps Runner =="

# Get environment variables
azure_token   = ENV.fetch("AZURE_ACCESS_TOKEN")
package_mgr   = ENV.fetch("PACKAGE_MANAGER", "npm")
project_path  = ENV.fetch("PROJECT_PATH")
directory     = ENV.fetch("DIRECTORY_PATH", "/")

puts "Organization: #{ENV.fetch('AZURE_ORG', 'N/A')}"
puts "Project: #{project_path}"
puts "Package Manager: #{package_mgr}"
puts "Directory: #{directory}"

# Create source for Azure DevOps (native provider)
source = Dependabot::Source.new(
  provider: "azure",
  repo: project_path,
  directory: directory
)

# Credentials for Azure DevOps only
credentials = [{
  "type" => "git_source",
  "host" => "dev.azure.com",
  "username" => "x-access-token",
  "password" => azure_token
}]

# Optional: NPM registry credentials if using Azure Artifacts
if ENV["AZURE_NPM_FEED_URL"] && ENV["AZURE_NPM_TOKEN"]
  credentials << {
    "type" => "npm_registry",
    "registry" => ENV["AZURE_NPM_FEED_URL"],
    "token" => ENV["AZURE_NPM_TOKEN"]
  }
  puts "Configured: Azure Artifacts NPM feed"
end

begin
  # Fetch dependency files from Azure DevOps
  puts "\n[Dependabot] Fetching dependency files from Azure DevOps..."
  fetcher = Dependabot::FileFetchers.for_package_manager(package_mgr).new(
    source: source,
    credentials: credentials
  )

  files = fetcher.files
  puts "[Dependabot] Found #{files.count} files"

  if files.empty?
    puts "[ERROR] No dependency files found at #{directory}"
    exit 1
  end

  files.each { |f| puts "  - #{f.name}" }

  # Parse dependencies
  puts "\n[Dependabot] Parsing dependencies..."
  parser = Dependabot::FileParsers.for_package_manager(package_mgr).new(
    dependency_files: files,
    source: source,
    credentials: credentials
  )

  dependencies = parser.parse
  puts "[Dependabot] Found #{dependencies.count} dependencies"

  if dependencies.empty?
    puts "[INFO] No dependencies found"
    exit 0
  end

  # Check for updates
  puts "\n[Dependabot] Checking for updates...\n"
  pr_count = 0
  
  dependencies.each do |dep|
    puts "  Checking: #{dep.name} (#{dep.version})"

    checker = Dependabot::UpdateCheckers.for_package_manager(package_mgr).new(
      dependency: dep,
      dependency_files: files,
      credentials: credentials
    )

    if checker.up_to_date?
      puts "    ✓ Up to date"
      next
    end

    updated_deps = checker.updated_dependencies
    puts "    → Updates available:"
    updated_deps.each do |updated|
      puts "      #{updated.name}: #{updated.previous_version} → #{updated.version}"
    end

    # Create Pull Request in Azure DevOps
    puts "    Creating pull request in Azure DevOps..."
    begin
      Dependabot::PullRequestCreator.new(
        source: source,
        base_commit: nil,
        dependencies: updated_deps,
        files: files,
        credentials: credentials,
        pr_message_header: "chore(deps): update #{dep.name}",
        pr_message_footer: "Automated dependency update via Dependabot",
        author_details: {
          name: "dependabot",
          email: "dependabot@textocorp.com"
        }
      ).create

      pr_count += 1
      puts "    ✓ PR created"
    rescue StandardError => e
      puts "    ✗ Failed to create PR: #{e.message}"
    end
  end

  puts "\n== Dependabot run completed =="
  puts "Total PRs created: #{pr_count}"
  exit 0

rescue StandardError => e
  puts "\n[ERROR] #{e.class}: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
end
