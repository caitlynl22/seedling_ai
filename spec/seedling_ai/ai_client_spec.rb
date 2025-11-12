# frozen_string_literal: true

require "spec_helper"
require "openai"

RSpec.describe SeedlingAi::AiClient do
  let(:prompt) { "Generate sample JSON for User" }
  let(:fake_client) { double("OpenAI::Client") }

  before do
    # Stubs
    stub_const("OpenAI::Errors::APIError", Class.new(StandardError))
    allow(SeedlingAi).to receive(:model).and_return("gpt-5")
    allow(SeedlingAi).to receive(:api_key).and_return("test-key")
    allow(OpenAI::Client).to receive(:new).and_return(fake_client)
  end

  describe ".generate" do
    context "when the API returns valid output_text" do
      let(:response) { { "output_text" => '[{"name":"Alice"}]' } }

      it "returns the text from the API response" do
        expect(fake_client).to receive(:responses)
          .with(parameters: hash_including(model: "gpt-5", input: prompt))
          .and_return(response)

        result = described_class.generate(prompt)
        expect(result).to eq('[{"name":"Alice"}]')
      end
    end

    context "when the API returns unexpected structure" do
      let(:response) { { "choices" => [] } }

      it "raises a descriptive error" do
        allow(fake_client).to receive(:responses).and_return(response)
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /No output_text returned/)
      end
    end

    context "when OpenAI::Errors::APIError is raised" do
      it "logs and raises a formatted message" do
        allow(fake_client).to receive(:responses).and_raise(OpenAI::Errors::APIError.new("timeout"))

        expect(SeedlingAi.logger).to receive(:error).with(/OpenAI API error/)
        expect { described_class.generate(prompt) }
          .to raise_error(RuntimeError, /OpenAI request failed/)
      end
    end

    context "when a generic StandardError occurs" do
      it "logs and re-raises the error" do
        allow(fake_client).to receive(:responses).and_raise(StandardError.new("network down"))

        expect(SeedlingAi.logger).to receive(:error).with(/Unexpected error/)
        expect { described_class.generate(prompt) }
          .to raise_error(StandardError, /network down/)
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
        client = double("OpenAI::Client")
        expect(OpenAI::Client).to receive(:new)
          .with(api_key: "test-key")
          .and_return(client)

        expect(described_class.send(:build_client)).to eq(client)
      end
    end
  end
end
