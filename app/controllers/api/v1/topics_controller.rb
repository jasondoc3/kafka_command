class Api::V1::TopicsController < Api::V1::BaseController
  rescue_from Kafka::InvalidPartitions, with: :invalid_partitions
  rescue_from Kafka::InvalidReplicationFactor, with: :invalid_replication_factor
  rescue_from Kafka::InvalidTopic, with: :invalid_topic

  # GET /api/v1/clusters/:cluster_id/topics
  def index
    cluster = Cluster.find(params[:cluster_id])
    render_json(cluster.topics)
  end

  # GET /api/v1/clusters/:cluster_id/topics/:id
  def show
    cluster = Cluster.find(params[:cluster_id])
    topic = cluster.topics.find { |t| t.name == params[:id] }

    if topic.nil?
      render_errors('Topic not found', status: 404)
    else
      render_json(topic)
    end
  end

  # POST /api/v1/clusters/:cluster_id/topics
  def create
    cluster = Cluster.find(params[:cluster_id])
    topic = cluster.create_topic(
      params[:name],
      num_partitions: params[:num_partitions].to_i,
      replication_factor: params[:replication_factor].to_i
    )

    render_json(topic)
  end

  # PATCH/PUT /api/v1/clusters/:cluster_id/topics
  def update
    cluster = Cluster.find(params[:cluster_id])
    topic = cluster.topics.find { |t| t.name == params[:id] }

    render_errors('Topic not found', status: 404) and return if topic.nil?
    if params[:num_partitions]
      topic.set_partitions!(params[:num_partitions].to_i)
    end

    render_json(topic)
  end

  # DELETE /api/v1/clusters/:cluster_id/topics/:id
  def destroy
    cluster = Cluster.find(params[:cluster_id])
    topic = cluster.topics.find { |t| t.name == params[:id] }

    if topic.nil?
      render_errors('Topic not found', status: 404)
    else
      topic.destroy
      head :no_content
    end
  end

  private

  def invalid_partitions
    render_errors('Num partitions must be > 0 or > current number of partitions', status: 422)
  end

  def invalid_replication_factor
    render_errors('Replication factor must be > 0 and < total number of brokers', status: 422)
  end

  def invalid_topic
    render_errors('Topic must have a name', status: 422)
  end
end
