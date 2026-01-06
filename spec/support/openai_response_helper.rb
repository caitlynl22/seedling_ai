# frozen_string_literal: true

# This module provides helper methods to process and format responses from the OpenAI API.
module OpenAIResponseHelper
  Response = Struct.new(:output, :error, keyword_init: true)

  def build_openai_response_with_text(text)
    Response.new(
      output: [
        {
          role: :assistant,
          content: [
            {
              type: :output_text,
              text: text
            }
          ]
        }
      ],
      error: nil
    )
  end

  def response_with_no_assistant
    Response.new(
      output: [
        {
          role: :system,
          content: [
            { type: :output_text, text: "hello" }
          ]
        }
      ]
    )
  end

  def response_with_assistant_but_no_output_text
    Response.new(
      output: [
        {
          role: :assistant,
          content: [
            { type: :tool_call, name: "foo" }
          ]
        }
      ]
    )
  end
end
