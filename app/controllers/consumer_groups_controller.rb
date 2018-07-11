class ConsumerGroupsController < ApplicationController

  # GET /clusters/:cluster_id/consumer_groups
  def index
    cluster = Cluster.find(params[:cluster_id])
    @groups = cluster.groups
    render_success(@groups)
  end

  # GET /alusters/:cluster_id/consumer_groups/:id
  def show
    cluster = Cluster.find(params[:cluster_id])
    @group = cluster.groups.find { |g| g.group_id == params[:id] }

    if @group.nil?
      render_error('Consumer group not found', status: 404)
    else
      render_success(@group)
    end
  end
end