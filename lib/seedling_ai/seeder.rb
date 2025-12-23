# frozen_string_literal: true

require "json"
require "yaml"
require "seedling_ai/ai_client"
require "seedling_ai/utils"

module SeedlingAi
  # Seeder class to generate and insert/export records for a given ActiveRecord model
  class Seeder
    include SeedlingAi::Utils

    VALID_EXPORT_FORMATS = %w[yaml json].freeze

    def initialize(model_name, count: 10, context: nil, export: nil)
      raise ArgumentError, "count must be >= 1" unless count.to_i.positive?

      @model = find_model(model_name)
      @count = count.to_i
      @context = context
      @export = export
    end

    def run
      SeedlingAi.logger.info "🌱 Generating #{@count} #{@model.name} records..."

      info = model_info(@model)
      prompt = build_prompt(info.summary)

      records = SeedlingAi::AiClient.generate(prompt)

      @export ? export(records) : insert_records(records)
    end

    private

    def build_prompt(summary)
      <<~PROMPT
        You are a Ruby on Rails data generation assistant.

        Using the following model details, generate #{@count} valid JSON objects.

        #{@context ? "Context: #{@context}" : ""}
        #{summary}

        Rules:
        - Exclude id, created_at, updated_at.
        - Use realistic data for each attribute.
        - Output ONLY valid JSON (array of objects).
      PROMPT
    end

    def export(records)
      unless VALID_EXPORT_FORMATS.include?(@export)
        raise ArgumentError, "Export format must be one of #{VALID_EXPORT_FORMATS.join(", ")}"
      end

      file_path = "db/seeds/#{@model.table_name}.#{@export}"
      data = @export == "yaml" ? records.to_yaml : JSON.pretty_generate(records)

      File.write(file_path, data)
      SeedlingAi.logger.info "📦 Exported #{@count} records to #{file_path}"
    end

    def insert_records(records)
      ActiveRecord::Base.transaction do
        @model.insert_all(records)
      end

      SeedlingAi.logger.info "✅ Inserted #{@count} records into #{@model.table_name}"
    rescue StandardError => e
      SeedlingAi.logger.error "❌ SeedlingAi: Failed to insert records - #{e.message}"
      SeedlingAi.logger.debug e.backtrace.join("\n")
      raise
    end
  end
end
