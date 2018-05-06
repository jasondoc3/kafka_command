require 'fast_helper'
require 'securerandom'
require 'kafka'
require 'config/initializers/kafka'

begin
  Kafka.new(seed_brokers: ['localhost:9092']).topics
rescue => e
  puts "#{e.class}. A Kafka broker running at localhost:9092 is required to run the specs."
  exit(0)
end

module KafkaHelpers
  def kafka_client
    Kafka.new(seed_brokers: ['localhost:9092'])
  end

  def create_topic(topic_name, **kwargs)
    kafka_client.create_topic(topic_name, **kwargs)
  end

  def delete_topic(topic_name)
    kafka_client.delete_topic(topic_name)
  end

  def list_topic_names
    kafka_client.topics
  end

  def deliver_message(msg, **kwargs)
    kafka_client.deliver_message(msg, **kwargs)
  end

  def partitions_for(topic_name)
    kafka_client.partitions_for(topic_name)
  end

  def create_partitions_for(topic_name, **kwargs)
    kafka_client.create_partitions_for(topic_name, **kwargs)
  end

  def topic_exists?(topic_name)
    return false if topic_name.nil? || topic_name.empty?
    list_topic_names.include?(topic_name)
  end
end

RSpec.configure do |config|
  config.include(KafkaHelpers)
end
