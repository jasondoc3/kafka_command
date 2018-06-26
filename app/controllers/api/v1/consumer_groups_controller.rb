class Api::V1::ConsumerGroupsController < Api::V1::BaseController

  # GET /api/v1/clusters/:cluster_id/consumer_groups
  def index
    cluster = Cluster.find(params[:cluster_id])
    @groups = cluster.groups
    render_json(@groups)
  end

  # GET /api/v1/clusters/:cluster_id/consumer_groups/:id
  def show
    cluster = Cluster.find(params[:cluster_id])
    @group = cluster.groups.find { |g| g.group_id == params[:id] }

    if @group.nil?
      render_errors('Consumer group not found', status: 404)
    else
      render_json(@group)
    end
  end
end
