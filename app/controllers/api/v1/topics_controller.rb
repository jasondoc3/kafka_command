class Api::V1::TopicsController < Api::V1::BaseController

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
    cluster.create_topic(
      params[:name],
      num_partitions: params[:num_partitions].to_i,
      replication_factor: params[:replication_factor].to_i
    )

    topic = cluster.topics.find { |t| t.name == params[:name] }
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
end
