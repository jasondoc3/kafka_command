require_dependency 'app/wrappers/kafka/group_member_wrapper'

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

    def dead?
      state.match?(/dead/i)
    end

    def topics
      topic_names = @members.flat_map(&:topic_names).uniq

      @cluster.topics.select do |t|
        topic_names.include?(t.name)
      end
    end

    def lag_for(topic_name)
      topic = topics.find { |t| t.name == topic_name }
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
      topic = topics.find { |t| t.name == topic_name }
      @coordinator.offsets_for(self, topic)
    end

    private

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
