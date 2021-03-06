# frozen_string_literal: true

require_dependency 'kafka_command/application_controller'

module KafkaCommand
  class TopicsController < ApplicationController
    rescue_from Kafka::InvalidPartitions, with: :invalid_partitions
    rescue_from Kafka::InvalidReplicationFactor, with: :invalid_replication_factor
    rescue_from Kafka::InvalidTopic, with: :invalid_topic_name
    rescue_from Kafka::TopicAlreadyExists, with: :topic_already_exists
    rescue_from Kafka::UnknownError, with: :unknown_error
    rescue_from Kafka::InvalidRequest, with: :unknown_error
    rescue_from Kafka::InvalidConfig, with: :unknown_error
    rescue_from Kafka::TopicAuthorizationFailed, with: :kafka_authorization_error
    rescue_from KafkaCommand::Topic::DeletionError, with: :topic_deletion_error

    # GET /clusters/:cluster_id/topics
    def index
      @cluster = Cluster.find(params[:cluster_id])
      @topics = @cluster.topics

      flash[:search] = params[:name]

      if params[:name].present?
        @topics = @topics.select do |t|
          regex = /#{params[:name]}/i
          t.name.match?(regex)
        end
      end

      render_success(@topics)
    end

    # GET /clusters/:cluster_id/topics/:id
    def show
      @cluster = Cluster.find(params[:cluster_id])
      @topic = @cluster.topics.find { |t| t.name == params[:id] }

      if @topic.nil?
        render_error('Topic not found', status: 404)
      else
        render_success(@topic, include_config: true)
      end
    end

    # GET /clusters/:cluster_id/topics/new
    def new
      @cluster = Cluster.find(params[:cluster_id])
    end

    # GET /clusters/:cluster_id/topics/edit
    def edit
      @cluster = Cluster.find(params[:cluster_id])
      @topic = @cluster.topics.find { |t| t.name == params[:id] }
      @redirect_path = params[:redirect_path]
    end

    # POST /clusters/:cluster_id/topics
    def create
      @cluster = Cluster.find(params[:cluster_id])
      @topic = @cluster.create_topic(
        params[:name],
        num_partitions: params[:num_partitions].to_i,
        replication_factor: params[:replication_factor].to_i,
        config: build_config
      )

      render_success(
        @topic,
        status: :created,
        redirection_path: cluster_topics_path,
        flash: { success: 'Topic created' },
        include_config: true
      )
    end

    # PATCH/PUT /clusters/:cluster_id/topics/:id
    def update
      cluster = Cluster.find(params[:cluster_id])
      @topic = cluster.topics.find { |t| t.name == params[:id] }

      render_error('Topic not found', status: 404) && (return) if @topic.nil?
      if params[:num_partitions]
        @topic.set_partitions!(params[:num_partitions].to_i) unless params[:num_partitions].to_i == @topic.partitions.count
      end

      if build_config.present?
        @topic.set_configs!(
          max_message_bytes: params[:max_message_bytes],
          retention_ms: params[:retention_ms],
          retention_bytes: params[:retention_bytes]
        )
      end

      render_success(
        @topic,
        status: :ok,
        redirection_path: params[:redirect_path] || cluster_topics_path,
        flash: { success: 'Topic updated' }
      )
    end

    # DELETE /clusters/:cluster_id/topics/:id
    def destroy
      @cluster = Cluster.find(params[:cluster_id])
      @topic = @cluster.topics.find { |t| t.name == params[:id] }

      if @topic.nil?
        render_error('Topic not found', status: 404)
      else
        @topic.destroy
        render_success(
          @topic,
          status: :no_content,
          redirection_path: cluster_topics_path,
          flash: { success: "Topic \"#{@topic.name}\" is marked for deletion. <strong>Note: This will have no impact if delete.topic.enable is not set to true.</strong>".html_safe }
        )
      end
    end

    private

      def build_config
        {}.tap do |config|
          config['max.message.bytes'] = params[:max_message_bytes] if params[:max_message_bytes]
          config['retention.ms']      = params[:retention_ms]      if params[:retention_ms]
          config['retention.bytes']   = params[:retention_bytes]   if params[:retention_bytes]
        end
      end

      def invalid_partitions
        render_error('Num partitions must be > 0 or > current number of partitions', status: 422)
      end

      def invalid_replication_factor
        render_error('Replication factor must be > 0 and < total number of brokers', status: 422)
      end

      def invalid_topic_name
        render_error('Topic must have a name', status: 422)
      end

      def topic_already_exists
        render_error('Topic already exists', status: 422)
      end

      def unknown_error
        render_error(
          'An unknown error occurred with the request to Kafka. Check any request parameters.',
          status: 422
        )
      end

      def topic_deletion_error(exception)
        render_error(exception.message, status: 422)
      end
  end
end
