# frozen_string_literal: true

require "spec_helper"
require "openai"

RSpec.describe SeedlingAi::AiClient do
  let(:prompt) { "Generate sample JSON for User" }
  let(:logger) { instance_spy(Logger) }

  let(:client) { instance_double(OpenAI::Client) }

  # This is an internal SDK proxy with no public class
  # We intentionally do NOT verify it against a constant
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:responses_proxy) { instance_spy("OpenAI::ResponsesProxy") }
  # rubocop:enable RSpec/VerifiedDoubleReference

  before do
    stub_const("OpenAI::Errors::APIError", Class.new(StandardError))

    allow(SeedlingAi).to receive_messages(
      model: "gpt-4.1-mini",
      api_key: "test-key",
      logger: logger
    )

    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(client).to receive(:responses).and_return(responses_proxy)
  end

  describe ".generate" do
    context "when the API returns valid JSON output_text" do
      let(:response) do
        instance_double(
          OpenAI::Models::Responses::Response,
          output: [
            {
              role: :assistant,
              content: [
                { type: :output_text, text: '[{"name":"Alice"}]' }
              ]
            }
          ]
        )
      end

      before do
        allow(responses_proxy).to receive(:create).and_return(response)
      end

      it "returns parsed JSON" do
        result = described_class.generate(prompt)

        expect(result).to eq([{ "name" => "Alice" }])
      end

      it "sends the correct parameters to OpenAI" do
        described_class.generate(prompt)

        expect(responses_proxy).to have_received(:create).with(
          hash_including(
            model: "gpt-4.1-mini",
            instructions: described_class::JSON_INSTRUCTIONS,
            max_output_tokens: 2048,
            temperature: 0.3
          )
        )
      end
    end

    context "when no output_text is returned" do
      let(:response) do
        instance_double(
          OpenAI::Models::Responses::Response,
          output: [
            {
              role: :assistant,
              content: []
            }
          ]
        )
      end

      before do
        allow(responses_proxy).to receive(:create).and_return(response)
      end

      it "raises a descriptive error" do
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /No output_text content/)
      end
    end

    context "when an OpenAI API error occurs" do
      before do
        allow(responses_proxy).to receive(:create)
          .and_raise(OpenAI::Errors::APIError.new("timeout"))
      end

      it "raises a formatted RuntimeError" do
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /OpenAI request failed/)
      end

      it "logs the API error" do
        expect { described_class.generate(prompt) }.to raise_error(RuntimeError)

        expect(logger).to have_received(:error).with(/OpenAI API error/)
      end
    end

    context "when a generic StandardError occurs" do
      before do
        allow(responses_proxy).to receive(:create)
          .and_raise(StandardError, "network down")
      end

      it "re-raises the error" do
        expect { described_class.generate(prompt) }
          .to raise_error(StandardError, /network down/)
      end

      it "logs the unexpected error" do
        expect { described_class.generate(prompt) }.to raise_error(StandardError)

        expect(logger).to have_received(:error).with(/Unexpected error/)
      end
    end
  end

  describe ".build_client" do
    context "when the API key is missing" do
      it "raises a clear configuration error" do
        allow(SeedlingAi).to receive(:api_key).and_return(nil)

        expect { described_class.send(:build_client) }
          .to raise_error(RuntimeError, /Missing OpenAI API key/)
      end
    end

    context "when the API key is present" do
      it "initializes OpenAI::Client with the correct key" do
        described_class.send(:build_client)

        expect(OpenAI::Client).to have_received(:new)
          .with(api_key: "test-key")
      end
    end
  end
end
