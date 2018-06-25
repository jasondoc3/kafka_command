require 'forwardable'

module Kafka
  class BrokerWrapper
    extend Forwardable
    attr_reader :broker
    def_delegators :@broker, :port, :host, :node_id, :fetch_metadata, :fetch_offsets

    def initialize(broker)
      @broker = broker
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
  end
end
