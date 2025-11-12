# frozen_string_literal: true

require "logger"
require_relative "seedling_ai/version"
require_relative "seedling_ai/utils"
require_relative "seedling_ai/ai_client"

require "seedling_ai/railtie" if defined?(Rails)

# Main module for SeedlingAi gem
module SeedlingAi
  class Error < StandardError; end
  class << self
    attr_writer :logger, :api_key, :model

    def logger
      @logger ||= if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
                    Rails.logger
                  else
                    Logger.new($stdout)
                  end
    end

    def api_key
      @api_key || ENV["OPENAI_API_KEY"]
    end

    def model
      @model || "gpt-4.1-mini"
    end

    def configure
      yield self
    end
  end
end
