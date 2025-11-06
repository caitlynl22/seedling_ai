# frozen_string_literal: true

require "logger"
require_relative "seedling_ai/version"
require_relative "seedling_ai/utils"

require "seedling_ai/railtie" if defined?(Rails)

module SeedlingAi
  class Error < StandardError; end
  class << self
    attr_writer :logger

    def logger
      @logger ||= if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
                    Rails.logger
                  else
                    Logger.new($stdout)
                  end
    end

    def configure
      yield self
    end
  end
end
