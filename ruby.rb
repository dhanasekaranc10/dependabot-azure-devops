
require "dependabot/source"
require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/pull_request_creator"


package_manager = ENV["PACKAGE_MANAGER"]
unless package_manager == "npm"
  raise "Unsupported PACKAGE_MANAGER '#{package_manager}'. This script supports npm only."
end


source = Dependabot::Source.new(
  provider: "azure",
  repo: ENV["PROJECT_PATH"],
  directory: ENV["DIRECTORY_PATH"]
)


credentials = [
  {
    "type" => "git_source",
    "host" => "dev.azure.com",
    "username" => "x-access-token",
    "password" => ENV["AZURE_ACCESS_TOKEN"]
  }
]


file_fetcher = Dependabot::FileFetchers.for_package_manager("npm").new(
  source: source,
  credentials: credentials
)

dependency_files = file_fetcher.files

if dependency_files.empty?
  puts "[Dependabot] No npm dependency files found. Exiting."
  exit 0
end

parser = Dependabot::FileParsers.for_package_manager("npm").new(
  dependency_files: dependency_files,
  source: source,
  credentials: credentials
)

dependencies = parser.parse

puts "[Dependabot] Found #{dependencies.count} npm dependencies"


dependencies.each do |dependency|
  puts "[Dependabot] Checking updates for #{dependency.name}"

  checker = Dependabot::UpdateCheckers.for_package_manager("npm").new(
    dependency: dependency,
    dependency_files: dependency_files,
    credentials: credentials
  )

  next if checker.up_to_date?

  updated_dependencies = checker.updated_dependencies

  Dependabot::PullRequestCreator.new(
    source: source,
    base_commit: nil,
    dependencies: updated_dependencies,
    files: dependency_files,
    credentials: credentials,
    pr_message_header: "deps(npm): bump #{dependency.name}",
    pr_message_footer: "Automated npm dependency update by Dependabot",
    author_details: {
      name: "dependabot",
      email: "dependabot@sagentlending.com"
    }
  ).create

  puts "[Dependabot] PR created for #{dependency.name}"
end
