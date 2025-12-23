# frozen_string_literal: true

require "openai"

module SeedlingAi
  # The AiClient handles communication with the OpenAI API
  class AiClient
    DEFAULT_PARAMS = { max_output_tokens: 2048, temperature: 0.3 }.freeze
    JSON_INSTRUCTIONS = <<~INSTRUCTIONS
      You are a JSON generator.
      You must return valid JSON only.
      Do not include markdown, code fences, comments, or explanations.
      The output must be directly parseable by JSON.parse.
    INSTRUCTIONS

    class << self
      def generate(prompt)
        client = build_client
        model = SeedlingAi.model

        SeedlingAi.logger.debug { "SeedlingAi: Sending prompt with model=#{model}" }

        response = client.responses.create(
          **DEFAULT_PARAMS,
          model: model,
          instructions: JSON_INSTRUCTIONS,
          input: [
            {
              role: :user,
              content: [
                { type: :input_text, text: prompt }
              ]
            }
          ]
        )

        text = extract_output_text(response)
        SeedlingAi.logger.debug { "SeedlingAi: Received #{text.length} chars from OpenAI" }

        parse_json(text)
      rescue OpenAI::Errors::APIError => e
        handle_api_error(e)
      rescue StandardError => e
        handle_generic_error(e)
      end

      private

      def build_client
        api_key = SeedlingAi.api_key

        if api_key.to_s.strip.empty?
          raise <<~ERROR.strip
            SeedlingAi Error: Missing OpenAI API key.

            Provide:
              - ENV['OPENAI_API_KEY'], OR
              - SeedlingAi.configure { |c| c.api_key = "your-key" }
          ERROR
        end

        OpenAI::Client.new(api_key: api_key)
      end

      def extract_output_text(response)
        message = response.output&.find { |m| m[:role] == :assistant }

        SeedlingAi.logger.error "SeedlingAi: No assistant message returned in Open API response: #{response.inspect}"
        raise "No assistant message in response" unless message

        text_blocks = message[:content].select { |c| c[:type] == :output_text }

        SeedlingAi.logger.error "SeedlingAi: No output_text content returned in Open API response: #{response.inspect}"
        raise "No output_text content in response" if text_blocks.empty?

        text_blocks.map { |c| c[:text] }.join("\n")
      end

      def parse_json(text)
        JSON.parse(text)
      rescue JSON::ParserError => e
        begin
          JSON.parse(strip_code_fences(text))
        rescue JSON::ParserError
          handle_json_error(e, text)
        end
      end

      def strip_code_fences(text)
        text.strip
            .sub(/\A```(?:json)?\s*/i, "")
            .sub(/\s*```\z/, "")
      end

      def handle_api_error(error)
        SeedlingAi.logger.error "SeedlingAi: OpenAI API error - #{error.class}: #{error.message}"
        raise "SeedlingAi: OpenAI request failed - #{error.message}"
      end

      def handle_json_error(error, text)
        SeedlingAi.logger.error "SeedlingAi: Failed to parse JSON output"
        SeedlingAi.logger.debug { text }
        raise "SeedlingAi: Unable to parse JSON output - #{error.message}"
      end

      def handle_generic_error(error)
        SeedlingAi.logger.error "SeedlingAi: Unexpected error calling OpenAI - #{error.message}"
        raise
      end
    end
  end
end
