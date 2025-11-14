# frozen_string_literal: true

require "spec_helper"

RSpec.describe SeedlingAi::Seeder do
  before do
    stub_const("User", Class.new(ActiveRecord::Base))
    allow(SeedlingAi).to receive(:logger).and_return(logger)
    allow(SeedlingAi::AiClient).to receive(:generate).and_return(json_data)
  end

  let(:model_class) { User }
  let(:records) { [{ "name" => "Alice" }, { "name" => "Bob" }] }
  let(:json_data) { records.to_json }
  let(:mock_info) { double(summary: "Model: User\nAttributes: name: string") }
  let(:logger) { instance_spy(Logger) }

  # Helper to create a seeder and stub instance-level model lookups cleanly
  def build_seeder(**opts)
    seeder = described_class.new("User", **opts)
    allow(seeder).to receive_messages(find_model: model_class, model_info: mock_info)
    seeder
  end

  describe "#initialize" do
    it "raises an error if count is less than 1" do
      expect { described_class.new("User", count: 0) }.to raise_error(ArgumentError, /count must be >= 1/)
    end

    it "sets the count from arguments" do
      seeder = described_class.new("User", count: 5)
      expect(seeder.instance_variable_get(:@count)).to eq(5)
    end

    it "sets the context from arguments" do
      seeder = described_class.new("User", context: "test")
      expect(seeder.instance_variable_get(:@context)).to eq("test")
    end
  end

  describe "#run" do
    context "when export is nil (inserts records)" do
      it "calls insert_all with parsed records" do
        seeder = build_seeder
        allow(ActiveRecord::Base).to receive(:transaction).and_yield
        allow(model_class).to receive(:insert_all)

        seeder.run

        expect(model_class).to have_received(:insert_all).with(records)
      end

      it "wraps insertion in a transaction" do
        seeder = build_seeder
        allow(model_class).to receive(:insert_all)
        allow(ActiveRecord::Base).to receive(:transaction).and_yield

        seeder.run

        expect(ActiveRecord::Base).to have_received(:transaction)
      end

      it "logs the number of inserted records" do
        seeder = build_seeder
        allow(model_class).to receive(:insert_all)
        allow(ActiveRecord::Base).to receive(:transaction).and_yield

        seeder.run

        expect(logger).to have_received(:info).with(/Inserted 10 records/)
      end
    end

    context "when export is 'json'" do
      it "writes JSON to db/seeds/users.json" do
        seeder = build_seeder(export: "json")
        allow(File).to receive(:write)

        seeder.run

        expect(File).to have_received(:write).with("db/seeds/users.json", JSON.pretty_generate(records))
      end

      it "logs the exported count" do
        seeder = build_seeder(export: "json")
        allow(File).to receive(:write)

        seeder.run

        expect(logger).to have_received(:info).with(/Exported 10 records/)
      end
    end

    context "when export is 'yaml'" do
      it "writes YAML to db/seeds/users.yaml" do
        seeder = build_seeder(export: "yaml")
        allow(File).to receive(:write)

        seeder.run

        expect(File).to have_received(:write).with("db/seeds/users.yaml", records.to_yaml)
      end

      it "logs the exported count for yaml" do
        seeder = build_seeder(export: "yaml")
        allow(File).to receive(:write)

        seeder.run

        expect(logger).to have_received(:info).with(/Exported 10 records/)
      end
    end

    context "when export format is invalid" do
      it "raises ArgumentError" do
        seeder = build_seeder(export: "csv")
        expect { seeder.run }.to raise_error(ArgumentError, /Export format must be one of/)
      end
    end

    context "when JSON parsing fails" do
      it "logs an error and raises JSON::ParserError" do
        allow(SeedlingAi::AiClient).to receive(:generate).and_return("invalid json")
        seeder = build_seeder

        allow(logger).to receive(:error)

        expect { seeder.run }.to raise_error(JSON::ParserError)
        expect(logger).to have_received(:error).with(/invalid JSON/)
      end
    end

    context "when insert_all raises an error" do
      it "logs and re-raises the exception" do
        seeder = build_seeder
        allow(model_class).to receive(:insert_all).and_raise(StandardError, "DB failure")
        allow(ActiveRecord::Base).to receive(:transaction).and_yield

        allow(logger).to receive(:error)

        expect { seeder.run }.to raise_error(StandardError, /DB failure/)
        expect(logger).to have_received(:error).with(/Failed to insert records/)
      end
    end
  end

  describe "#build_prompt" do
    it "includes the requested count" do
      seeder = build_seeder(count: 5, context: "Include sample emails")
      prompt = seeder.send(:build_prompt, "Model: User")

      expect(prompt).to include("5 valid JSON objects")
    end

    it "includes provided context" do
      seeder = build_seeder(count: 5, context: "Include sample emails")
      prompt = seeder.send(:build_prompt, "Model: User")

      expect(prompt).to include("Include sample emails")
    end

    it "includes the model summary" do
      seeder = build_seeder(count: 5, context: "Include sample emails")
      prompt = seeder.send(:build_prompt, "Model: User")

      expect(prompt).to include("Model: User")
    end

    it "omits context if not provided" do
      seeder = build_seeder(count: 3)
      prompt = seeder.send(:build_prompt, "Model: User")

      expect(prompt).not_to include("Context:")
    end

    it "includes the requested count when context is omitted" do
      seeder = build_seeder(count: 3)
      prompt = seeder.send(:build_prompt, "Model: User")

      expect(prompt).to include("3 valid JSON objects")
    end
  end
end
