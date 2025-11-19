# frozen_string_literal: true

require "spec_helper"

RSpec.describe SeedlingAi::CLI do
  let(:logger) { instance_spy(Logger) }
  let(:seeder_instance) { instance_double(SeedlingAi::Seeder, run: true) }

  before do
    allow(SeedlingAi).to receive(:logger).and_return(logger)
    allow(SeedlingAi::Seeder).to receive(:new).and_return(seeder_instance)
  end

  describe "#seed" do
    it "initializes Seeder with correct arguments" do
      described_class.start(["seed", "User", "--count", "5", "--context", "hello", "--export", "json"])

      expect(SeedlingAi::Seeder).to have_received(:new).with(
        "User",
        count: 5,
        context: "hello",
        export: "json"
      )
    end

    it "runs the seeder" do
      described_class.start(%w[seed User])
      expect(seeder_instance).to have_received(:run)
    end

    context "when Seeder raises ArgumentError" do
      before do
        allow(SeedlingAi::Seeder).to receive(:new).and_raise(ArgumentError, "Bad model")
        allow(described_class).to receive(:exit).with(1)
      end

      it "prints the error and logs it" do
        output = capture_stdout do
          described_class.start(%w[seed User])
        end

        expect(output).to include("Error: Bad model")
        expect(logger).to have_received(:error).with("Error: Bad model")
      end
    end

    context "when JSON::ParserError is raised" do
      before do
        allow(seeder_instance).to receive(:run).and_raise(JSON::ParserError)
        allow(described_class).to receive(:exit).with(1)
      end

      it "prints a JSON error message" do
        output = capture_stdout do
          described_class.start(%w[seed User])
        end

        expect(output).to include("Error: Invalid JSON returned from AI")
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow(seeder_instance).to receive(:run).and_raise(StandardError, "Boom")
        allow(described_class).to receive(:exit).with(1)
      end

      it "prints and logs the unexpected error" do
        output = capture_stdout do
          described_class.start(%w[seed User])
        end

        expect(output).to include("Unexpected Error: Boom")
        expect(logger).to have_received(:error).with("Unexpected Error: Boom")
      end
    end
  end

  describe "#version" do
    it "prints the version string" do
      output = capture_stdout do
        described_class.start(["version"])
      end

      expect(output).to include("SeedlingAI version #{SeedlingAi::VERSION}")
    end
  end

  # Helper — captures stdout in specs that use puts
  def capture_stdout
    original_stdout = $stdout
    fake = StringIO.new
    $stdout = fake
    yield
    fake.string
  ensure
    $stdout = original_stdout
  end
end
