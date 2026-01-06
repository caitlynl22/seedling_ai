# frozen_string_literal: true

require "spec_helper"
require "openai"

RSpec.describe SeedlingAi::AiClient do
  let(:prompt) { "Generate sample JSON for User" }
  let(:logger) { instance_spy(Logger) }

  # This is an internal SDK proxy with no public class
  # We intentionally do NOT verify it against a constant
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:responses_proxy) { instance_spy("ResponsesProxy") }
  # rubocop:enable RSpec/VerifiedDoubleReference
  let(:fake_client) { instance_spy(OpenAI::Client, responses: responses_proxy) }

  before do
    stub_const("OpenAI::Errors::APIError", Class.new(StandardError))

    allow(SeedlingAi).to receive_messages(
      model: "gpt-4.1-mini",
      api_key: "test-key",
      logger: logger
    )

    allow(OpenAI::Client).to receive(:new).and_return(fake_client)
  end

  describe ".generate" do
    context "when the API returns valid JSON output_text" do
      let(:valid_json) { '[{ "name": "Alice" }]' }

      before do
        allow(responses_proxy).to receive(:create).and_return(build_openai_response_with_text(valid_json))
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

    context "when no assistant message is returned" do
      before do
        allow(responses_proxy).to receive(:create)
          .and_return(response_with_no_assistant)
      end

      it "raises a clear error" do
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /No assistant message in response/)
      end

      it "logs an error for debugging" do
        expect do
          described_class.generate(prompt)
        end.to raise_error(RuntimeError)

        expect(logger).to have_received(:error)
          .with(/No assistant message returned/)
      end
    end

    context "when the assistant message has no output_text content" do
      before do
        allow(responses_proxy).to receive(:create)
          .and_return(response_with_assistant_but_no_output_text)
      end

      it "raises a clear error" do
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /No output_text content in response/)
      end

      it "logs an error for debugging" do
        expect do
          described_class.generate(prompt)
        end.to raise_error(RuntimeError)

        expect(logger).to have_received(:error)
          .with(/No output_text content returned/)
      end
    end

    context "when the model returns invalid JSON" do
      let(:invalid_json) { '{ name: "Alice"' }

      before do
        allow(responses_proxy).to receive(:create).and_return(build_openai_response_with_text(invalid_json))
      end

      it "raises a descriptive JSON parsing error" do
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /Unable to parse JSON output/)
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
