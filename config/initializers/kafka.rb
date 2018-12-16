# frozen_string_literal: true

require 'core_extensions/kafka/broker/attr_readers'
require 'core_extensions/kafka/broker_pool/attr_readers'
require 'core_extensions/kafka/client/attr_readers'
require 'core_extensions/kafka/cluster/attr_readers'
require 'core_extensions/kafka/protocol/metadata_response/partition_metadata/attr_readers'

Kafka::Broker.include CoreExtensions::Kafka::Broker::AttrReaders
Kafka::BrokerPool.include CoreExtensions::Kafka::BrokerPool::AttrReaders
Kafka::Client.include CoreExtensions::Kafka::Client::AttrReaders
Kafka::Cluster.include CoreExtensions::Kafka::Cluster::AttrReaders
Kafka::Protocol::MetadataResponse::PartitionMetadata.include CoreExtensions::Kafka::Protocol::MetadataResponse::PartitionMetadata::AttrReaders
