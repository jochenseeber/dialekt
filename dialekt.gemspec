# frozen_string_literal: true

LIB_DIR = File.join(__dir__, "lib")
$LOAD_PATH.unshift(LIB_DIR) unless $LOAD_PATH.include?(LIB_DIR)

require "dialekt/version"
require "json"
require "pathname"

Gem::Specification.new do |spec|
  raise "RubyGems 2.0 or newer is required." unless spec.respond_to?(:metadata)

  spec.name = "dialekt"
  spec.version = Dialekt::VERSION
  spec.summary = "DSL utilities"

  spec.required_ruby_version = ">= 2.6"

  spec.authors = ["Jochen Seeber"]
  spec.email = ["jochen@seeber.me"]
  spec.homepage = "https://github.com/jochenseeber/dialekt"

  spec.metadata["issue_tracker"] = "https://github.com/jochenseeber/dialekt/issues"
  spec.metadata["documentation"] = "http://jochenseeber.github.com/dialekt"
  spec.metadata["source_code"] = "https://github.com/jochenseeber/dialekt"
  spec.metadata["wiki"] = "https://github.com/jochenseeber/dialekt/wiki"

  spec.files = Dir[
    "*.gemspec",
    "*.md",
    "*.txt",
    "lib/**/*.rb",
  ]

  spec.require_paths = [
    "lib",
  ]

  spec.bindir = "cmd"
  spec.executables = spec.files.filter { |f| File.dirname(f) == "cmd" && File.file?(f) }.map { |f| File.basename(f) }

  spec.add_dependency "docile", "~> 1.3.5"
  spec.add_dependency "dry-inflector", "~> 0.2"
  spec.add_dependency "zeitwerk", "~> 2.3"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "calificador", "~> 0.2.0"
  spec.add_development_dependency "debase", "~> 0.2"
  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "qed", "~> 2.9"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.6"
  spec.add_development_dependency "rubocop-minitest", "~> 0.10"
  spec.add_development_dependency "rubocop-rake", "~> 0.5"
  spec.add_development_dependency "ruby-debug-ide", "~> 0.7"
  spec.add_development_dependency "simplecov", "~> 0.18"
  spec.add_development_dependency "yard", "~> 0.9"
end
