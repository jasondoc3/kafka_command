require 'fast_helper'
require 'securerandom'
require 'kafka'
require 'config/initializers/kafka'

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

def partitions_for(topic)
  kafka_client.partitions_for(topic)
end

def topic_exists?(topic)
  list_topic_names.include?(topic)
end
