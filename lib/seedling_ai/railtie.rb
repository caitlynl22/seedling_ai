# frozen_string_literal: true

require "rails/railtie"

module SeedlingAi
  # A Railtie to integrate SeedlingAi with Rails applications.
  class Railtie < Rails::Railtie
    initializer "seedling_ai.setup_logger" do
      SeedlingAi.logger = Rails.logger if defined?(Rails) && Rails.logger
    end

    rake_tasks do
      load File.expand_path("../tasks/seedling_ai.rake", __dir__)
    end
  end
end
