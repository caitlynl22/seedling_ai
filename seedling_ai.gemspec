# frozen_string_literal: true

require_relative "lib/seedling_ai/version"

Gem::Specification.new do |spec|
  spec.name = "seedling_ai"
  spec.version = SeedlingAi::VERSION
  spec.authors = ["Caitlyn Landry"]
  spec.email = ["caitlyn.landry@gmail.com"]

  spec.summary = "A command line tool to help you grow your ideas with the OpenAI API."
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/caitlynl22/seedling_ai"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/caitlynl22/seedling_ai"
  spec.metadata["changelog_uri"] = "https://github.com/caitlynl22/seedling_ai/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "activerecord", "~> 7.1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sqlite3", "~> 1.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
