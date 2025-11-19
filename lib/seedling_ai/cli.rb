# frozen_string_literal: true

require "thor"
require "seedling_ai/seeder"

module SeedlingAi
  # Command Line Interface using Thor
  class CLI < Thor
    desc "seed MODEL", "Generate seed data for the specified ActiveRecord MODEL"
    method_option :count, type: :numeric, default: 10, desc: "Number of records to generate (defaulyt: 10)"
    method_option :export, type: :string, desc: "Export generated data to a file (yaml or json)"
    method_option :context, type: :string, desc: "Additional natural-language context to guide data generation"

    def seed(model)
      seeder = SeedlingAi::Seeder.new(
        model,
        count: options[:count],
        context: options[:context],
        export: options[:export]
      )
      seeder.run
    rescue ArgumentError => e
      handle_argument_error(e)
    rescue JSON::ParserError
      handle_json_error
    rescue StandardError => e
      handle_generic_error(e)
    end

    desc "version", "Display the version of SeedlingAI"
    def version
      puts "SeedlingAI version #{SeedlingAi::VERSION}"
    end

    def self.exit_on_failure?
      true
    end

    private

    def handle_argument_error(error)
      SeedlingAi.logger.error "Error: #{error.message}"
      puts "Error: #{error.message}"
    end

    def handle_json_error
      SeedlingAi.logger.error "Error: Invalid JSON returned from AI."
      puts "Error: Invalid JSON returned from AI. Check logs for details."
    end

    def handle_generic_error(error)
      SeedlingAi.logger.error "Unexpected Error: #{error.message}"
      puts "Unexpected Error: #{error.message}"
    end
  end
end
