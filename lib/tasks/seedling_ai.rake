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

    safely_run_cli(args_for_cli)
  end

  desc "List available ActiveRecord models"
  task list_models: :environment do
    safely_run_cli(["list_models"])
  end

  desc "Print SeedlingAI version"
  task :version do
    safely_run_cli(["version"])
  end

  private

  def safely_run_cli(args)
    SeedlingAi::CLI.start(args)
  rescue SystemExit => e
    raise e if e.status != 0
  end
end
