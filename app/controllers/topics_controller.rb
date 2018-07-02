class TopicsController < ApplicationController
  rescue_from Kafka::InvalidPartitions, with: :invalid_partitions
  rescue_from Kafka::InvalidReplicationFactor, with: :invalid_replication_factor
  rescue_from Kafka::InvalidTopic, with: :invalid_topic

  # GET /clusters/:cluster_id/topics
  def index
    cluster = Cluster.find(params[:cluster_id])
    @topics = cluster.topics

    render_success(@topics)
  end

  # GET /clusters/:cluster_id/topics/:id
  def show
    cluster = Cluster.find(params[:cluster_id])
    @topic = cluster.topics.find { |t| t.name == params[:id] }

    if @topic.nil?
      render_error('Topic not found', status: 404)
    else
      render_success(@topic)
    end
  end

  # POST /clusters/:cluster_id/topics
  def create
    cluster = Cluster.find(params[:cluster_id])
    @topic = cluster.create_topic(
      params[:name],
      num_partitions: params[:num_partitions].to_i,
      replication_factor: params[:replication_factor].to_i
    )

    render_success(@topic, status: :created)
  end

  # PATCH/PUT /clusters/:cluster_id/topics
  def update
    cluster = Cluster.find(params[:cluster_id])
    @topic = cluster.topics.find { |t| t.name == params[:id] }

    render_error('Topic not found', status: 404) and return if @topic.nil?
    if params[:num_partitions]
      @topic.set_partitions!(params[:num_partitions].to_i)
    end

    render_success(@topic)
  end

  # DELETE /clusters/:cluster_id/topics/:id
  def destroy
    cluster = Cluster.find(params[:cluster_id])
    @topic = cluster.topics.find { |t| t.name == params[:id] }

    if @topic.nil?
      render_error('Topic not found', status: 404)
    else
      @topic.destroy
      render_success(@topic, status: :no_content)
    end
  end

  private

  def invalid_partitions
    render_error('Num partitions must be > 0 or > current number of partitions', status: 422)
  end

  def invalid_replication_factor
    render_error('Replication factor must be > 0 and < total number of brokers', status: 422)
  end

  def invalid_topic
    render_error('Topic must have a name', status: 422)
  end
end
