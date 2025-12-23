# frozen_string_literal: true

require "openai"

module SeedlingAi
  # The AiClient handles communication with the OpenAI API
  class AiClient
    class << self
      DEFAULT_PARAMS = { max_output_tokens: 2048, temperature: 0.3 }.freeze
      JSON_INSTRUCTIONS = <<~INSTRUCTIONS
        You are a JSON generator.
        You must return valid JSON only.
        Do not include markdown, code fences, comments, or explanations.
        The output must be directly parseable by JSON.parse.
      INSTRUCTIONS

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
        text.strip
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
        text = response["output_text"]
        return text if text.is_a?(String)

        SeedlingAi.logger.error "SeedlingAi: Unexpected OpenAI response: #{response.inspect}"
        raise "SeedlingAi: No output_text returned from OpenAI"
      end

      def handle_api_error(error)
        SeedlingAi.logger.error "SeedlingAi: OpenAI API error - #{error.class}: #{error.message}"
        raise "SeedlingAi: OpenAI request failed - #{error.message}"
      end

      def handle_generic_error(error)
        SeedlingAi.logger.error "SeedlingAi: Unexpected error calling OpenAI - #{error.message}"
        raise
      end
    end
  end
end
