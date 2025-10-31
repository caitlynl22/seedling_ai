# frozen_string_literal: true

require_relative "seedling_ai/version"
require_relative 'seedling_ai/utils'

require "seedling_ai/railtie" if defined?(Rails)

module SeedlingAi
  class Error < StandardError; end
  # Your code goes here...
end
