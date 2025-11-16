# frozen_string_literal: true

require "spec_helper"
require "openai"

RSpec.describe SeedlingAi::AiClient do
  let(:prompt) { "Generate sample JSON for User" }
  # rubocop:disable RSpec/VerifiedDoubles
  let(:fake_client) { double("OpenAI::Client") }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:logger) { instance_spy(Logger) }

  before do
    # Fake error class (SDK defines actual subclasses but we only need APIError)
    stub_const("OpenAI::Errors::APIError", Class.new(StandardError))

    allow(SeedlingAi).to receive_messages(
      model: "gpt-5",
      api_key: "test-key",
      logger: logger
    )

    allow(OpenAI::Client).to receive(:new).and_return(fake_client)
  end

  describe ".generate" do
    context "when the API returns valid output_text" do
      let(:response) { { "output_text" => '[{"name":"Alice"}]' } }

      it "returns the text" do
        allow(fake_client).to receive(:responses).and_return(response)

        result = described_class.generate(prompt)

        expect(result).to eq('[{"name":"Alice"}]')
      end

      it "sends correct parameters to the client" do
        allow(fake_client).to receive(:responses).and_return(response)

        described_class.generate(prompt)

        expect(fake_client).to have_received(:responses)
          .with(parameters: hash_including(model: "gpt-5", input: prompt))
      end
    end

    context "when the API returns an unexpected structure" do
      let(:response) { { "choices" => [] } }

      it "raises a descriptive error" do
        allow(fake_client).to receive(:responses).and_return(response)

        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /No output_text returned/)
      end
    end

    context "when an OpenAI API error occurs" do
      before do
        allow(fake_client).to receive(:responses)
          .and_raise(OpenAI::Errors::APIError.new("timeout"))
      end

      it "raises a formatted RuntimeError" do
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /OpenAI request failed/)
      end

      it "logs the error" do
        expect do
          described_class.generate(prompt)
        end.to raise_error(RuntimeError)

        expect(logger).to have_received(:error).with(/OpenAI API error/)
      end
    end

    context "when a generic StandardError occurs" do
      before do
        allow(fake_client).to receive(:responses)
          .and_raise(StandardError.new("network down"))
      end

      it "re-raises the error" do
        expect { described_class.generate(prompt) }
          .to raise_error(StandardError, /network down/)
      end

      it "logs the unexpected error" do
        expect do
          described_class.generate(prompt)
        end.to raise_error(StandardError)

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
      it "returns an OpenAI::Client instance" do
        client = described_class.send(:build_client)

        expect(client).to be(fake_client)
      end

      it "initializes OpenAI::Client with the correct key" do
        described_class.send(:build_client)

        expect(OpenAI::Client).to have_received(:new)
          .with(api_key: "test-key")
      end
    end
  end
end
