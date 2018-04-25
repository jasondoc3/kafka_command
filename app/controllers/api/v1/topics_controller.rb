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
end
