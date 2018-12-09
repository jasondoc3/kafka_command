require 'forwardable'

module KafkaCommand
  class Broker
    extend Forwardable
    attr_reader :broker
    def_delegators :@broker, :port, :host, :node_id, :fetch_metadata, :fetch_offsets
    alias_method :kafka_broker_id, :node_id
    alias_method :hostname, :host

    def initialize(broker)
      @broker = broker
    end

    def host_with_port
      "#{host}:#{port}"
    end

    def as_json(*)
      {
        id: node_id,
        host: host_with_port
      }
    end

    # needs to be the group coordinator to work
    def offsets_for(group, topic)
      offsets = @broker.fetch_offsets(
        group_id: group.group_id,
        topics: { topic.name => topic.partitions.map(&:partition_id) }
      ).topics[topic.name]

      offsets.keys.each { |partition_id| offsets[partition_id] = offsets[partition_id].offset }
      offsets
    end

    def connected?
      @broker.api_versions # simple request to check connections
      true
    rescue Kafka::ConnectionError
      false
    end
  end
end
