require_dependency 'app/wrappers/kafka/group_member_wrapper'
require_dependency 'app/wrappers/kafka/consumer_group_partition_wrapper'

module Kafka
  class ConsumerGroupWrapper
    attr_reader :group_id, :members, :state

    def initialize(group_metadata, cluster)
      @cluster = cluster
      initialize_from_metadata(group_metadata)
    end

    def refresh!
      group_metadata = @cluster.describe_group(@group_id)
      initialize_from_metadata(group_metadata)
    end

    def stable?
      state.match?(/stable/i)
    end

    def empty?
      state.match?(/empty/i) || members.none?
    end

    def topics
      topic_names = @members.flat_map(&:topic_names).uniq

      @cluster.topics.select do |t|
        topic_names.include?(t.name)
      end
    end

    def partitions_for(topic_name)
      topic = find_topic(topic_name)
      partition_lag = lag_for(topic.name)

      topic.partitions.map do |p|
        ConsumerGroupPartitionWrapper.new(
          lag: partition_lag[p.partition_id],
          group_id: @group_id,
          topic_name: topic.name,
          partition_id: p.partition_id
        )
      end
    end

    def as_json(*)
      topics_json = topics.map do |topic|
        {
          name: topic.name,
          partitions: partitions_for(topic.name).map(&:as_json)
        }.with_indifferent_access
      end

      {
        group_id: @group_id,
        topics: topics_json
      }.with_indifferent_access
    end

    private

    def find_topic(topic_name)
      topics.find { |t| t.name == topic_name }
    end

    def lag_for(topic_name)
      topic = find_topic(topic_name)
      topic_offsets = topic.offsets
      group_offsets = offsets_for(topic_name)

      lag_hash = compute_lag(topic_offsets, group_offsets)
      lag_hash.each_with_object({}) do |(partition_id, lag), return_hash|
        return_hash[partition_id] = {
          offset: group_offsets[partition_id],
          lag: lag
        }
      end
    end

    def offsets_for(topic_name)
      topic = find_topic(topic_name)

      offsets = @coordinator.fetch_offsets(
        group_id: @group_id,
        topics: { topic.name => topic.partitions.map(&:partition_id) }
      ).topics[topic.name]

      offsets.keys.each { |partition_id| offsets[partition_id] = offsets[partition_id].offset }
      offsets
    end

    def compute_lag(topic_offsets, group_offsets)
      topic_offsets.each_with_object({}) do |(partition_id, latest_offset), lag_hash|
        lag =
          if group_offsets[partition_id] >= latest_offset
            0
          else
            latest_offset - group_offsets[partition_id]
          end

        lag_hash[partition_id] = lag
      end
    end

    def initialize_from_metadata(group_metadata)
      @group_id = group_metadata.group_id
      @state    = group_metadata.state
      @coordinator = @cluster.get_group_coordinator(group_id: @group_id)

      @members = group_metadata.members.map do |member|
        GroupMemberWrapper.new(member)
      end
    end
  end
end
