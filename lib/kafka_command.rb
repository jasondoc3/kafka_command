require "kafka_command/engine"
require "kafka"

module KafkaCommand
  class << self
    attr_accessor :config
  end
end
