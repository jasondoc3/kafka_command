# frozen_string_literal: true

require 'kafka_command/engine'
require 'kafka'
require 'kafka_command/configuration'
require 'kafka_command/errors'

if defined?(Rails) && Rails::VERSION::MAJOR < 5
  require 'rails-ujs'
end

module KafkaCommand
end
