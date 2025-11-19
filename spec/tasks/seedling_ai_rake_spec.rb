# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "seedling_ai rake tasks", type: :task do
  let(:cli) { class_double(SeedlingAi::CLI) }
  let(:logger) { instance_spy(Logger) }

  let(:rake_file_paths) do
    [
      File.expand_path("lib/tasks/seedling_ai.rake", Dir.pwd),
      File.expand_path("../../../lib/tasks/seedling_ai.rake", __dir__)
    ]
  end

  before do
    # Create a fresh Rake application so tasks from other tests don't leak in.
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment) # satisfy dependency

    # Find and load the rake file from the project (support a couple of common paths).
    rake_file = rake_file_paths.find { |p| File.exist?(p) }
    raise "Could not find lib/tasks/seedling_ai.rake to load in spec" unless rake_file

    load rake_file

    stub_const("SeedlingAi::CLI", cli)
    allow(cli).to receive(:start)

    allow(SeedlingAi).to receive(:logger).and_return(logger)
  end

  after do
    # Reset Rake application state between examples
    Rake.application = nil
    # Ensure ENV cleanup between tests
    %w[MODEL COUNT CONTEXT EXPORT model count context export].each { |k| ENV.delete(k) }
  end

  it "defines seed and version tasks" do
    expect(Rake::Task.task_defined?("seedling_ai:seed")).to be true
    expect(Rake::Task.task_defined?("seedling_ai:version")).to be true
  end

  it "invokes SeedlingAi::CLI.start with positional args" do
    task = Rake::Task["seedling_ai:seed"]
    task.reenable
    task.invoke("User", "5", "some context", "json")

    expect(cli).to have_received(:start).with(
      ["seed", "User", "--count", "5", "--context", "some context", "--export", "json"]
    )
  end

  it "falls back to ENV variables when positional args are not supplied" do
    ENV["MODEL"] = "UserFromEnv"
    ENV["COUNT"] = "7"
    ENV["CONTEXT"] = "env context"
    ENV["EXPORT"] = "yaml"

    task = Rake::Task["seedling_ai:seed"]
    task.reenable
    task.invoke

    expect(cli).to have_received(:start).with(
      ["seed", "UserFromEnv", "--count", "7", "--context", "env context", "--export", "yaml"]
    )
  end

  it "aborts when MODEL is not provided" do
    task = Rake::Task["seedling_ai:seed"]
    task.reenable

    expect { task.invoke }.to raise_error(SystemExit)
  end

  it "re-raises non-zero SystemExit from the CLI" do
    allow(cli).to receive(:start).and_raise(SystemExit.new(1))

    task = Rake::Task["seedling_ai:seed"]
    task.reenable

    expect { task.invoke("User") }.to raise_error(SystemExit)
  end

  it "does not raise when CLI exits with status 0 (swallowed by task)" do
    allow(cli).to receive(:start).and_raise(SystemExit.new(0))

    task = Rake::Task["seedling_ai:seed"]
    task.reenable

    expect { task.invoke("User") }.not_to raise_error
  end
end
