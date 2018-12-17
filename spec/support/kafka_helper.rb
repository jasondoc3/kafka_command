# frozen_string_literal: true

require 'fast_helper'
require 'securerandom'
require 'kafka'
require 'lib/kafka_command/configuration'
require 'lib/kafka_command/errors'
require 'config/initializers/kafka'
require 'app/models/kafka_command/client'
require 'app/models/kafka_command/broker'
require 'app/models/kafka_command/cluster'
require 'app/models/kafka_command/topic'
require 'app/models/kafka_command/consumer_group'
require 'app/models/kafka_command/partition'
require 'app/models/kafka_command/consumer_group_partition'
require 'app/models/kafka_command/group_member'

$LOAD_PATH.unshift(File.expand_path('.'))
ENV['RAILS_ENV'] = 'test'

KafkaCommand::Configuration.load!('spec/dummy/config/kafka_command.yml')

begin
  KafkaCommand::Cluster.all.first.topics
rescue => e
  puts "#{e.class}. An online kafka cluster is required to run the specs."
  exit(0)
end

module KafkaHelpers
  def kafka_command_cluster
    KafkaCommand::Cluster.all.find { |c| c.name == 'test_cluster' }
  end

  def kafka_client
    Kafka.new(ENV['SEED_BROKERS'].split(','))
  end

  def create_topic(topic_name, **kwargs)
    kafka_client.create_topic(topic_name, **kwargs)
    sleep_if_necessary
  end

  def delete_topic(topic_name)
    kafka_client.delete_topic(topic_name)
    sleep_if_necessary
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
    sleep_if_necessary
  end

  def topic_exists?(topic_name)
    return false if topic_name.nil? || topic_name.empty?
    list_topic_names.include?(topic_name)
  end

  def run_consumer_group(topic_name, group_id, num_messages_to_consume: 0)
    deliver_message('test', topic: topic_name)
    consumer = kafka_client.consumer(group_id: group_id)
    consumer.subscribe(topic_name)

    message_counter = 0
    num_messages_to_consume += 1
    consumer.each_message do |msg|
      yield if block_given?
      message_counter += 1
      consumer.stop if message_counter >= num_messages_to_consume
    end
  end

  # Sleep if more than one broker is in the cluster to fix flaky tests
  def sleep_if_necessary
    sleep(0.5) if ENV['SEED_BROKERS'].split(',').count > 1
  end
end

RSpec.configure do |config|
  config.include(KafkaHelpers)
end
