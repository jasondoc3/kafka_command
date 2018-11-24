module KafkaCommand
  class GroupMemberWrapper
    attr_reader :member_id, :client_host, :client_id, :topic_assignment

    def initialize(member_metadata)
      @member_id = member_metadata.member_id
      @client_host = member_metadata.client_host
      @client_id = member_metadata.client_id
      @topic_assignment = member_metadata.member_assignment.topics
    end

    def topic_names
      @topic_assignment.keys
    end
  end
end
