require "kafka_command/engine"
require "kafka"
require "attr_encrypted"

module KafkaCommand
  class << self
    attr_accessor :config
  end
end
