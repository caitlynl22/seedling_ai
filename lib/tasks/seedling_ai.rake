# frozen_string_literal: true

require "seedling_ai/cli" unless defined?(SeedlingAi::CLI)

namespace :seedling_ai do
  desc <<~DESC
    Generate seed data using SeedlingAI.

    Usage examples:

      rails seedling_ai:seed MODEL=User COUNT=10 EXPORT=json CONTEXT='extra details'
      rake seedling_ai:seed[User,5,'extra details','json']
  DESC
  task :seed, %i[model count context export] => :environment do |_t, args|
    model   = args[:model]   || ENV["MODEL"]   || ENV["model"]
    count   = args[:count]   || ENV["COUNT"]   || ENV["count"] || "10"
    context = args[:context] || ENV["CONTEXT"] || ENV["context"]
    export  = args[:export]  || ENV["EXPORT"]  || ENV["export"]

    abort "MODEL is required. Example: MODEL=User rake seedling_ai:seed" if model.nil? || model.to_s.strip.empty?

    args_for_cli = ["seed", model.to_s, "--count", count.to_s]
    args_for_cli += ["--context", context.to_s] if context && !context.to_s.empty?
    args_for_cli += ["--export", export.to_s.downcase] if export && !export.to_s.empty?

    begin
      SeedlingAi::CLI.start(args_for_cli)
    rescue SystemExit => e
      # Prevent the CLI from terminating the rake process.
      # Re-raise for non-zero status so CI/test runners observe failures.
      raise e if e.status != 0
    end
  end

  desc "Print SeedlingAI version"
  task :version do
    puts "SeedlingAI version #{SeedlingAi::VERSION}"
  end
end
