module KafkaCommand
  class ConsumerGroupsController < ApplicationController

    # GET /clusters/:cluster_id/consumer_groups
    def index
      @cluster = Cluster.find(params[:cluster_id])
      @groups = @cluster.groups

      flash[:search] = params[:group_id]

      if params[:group_id].present?
        @groups = @groups.select do |g|
          regex = /#{params[:group_id]}/i
          g.group_id.match?(regex)
        end
      end

      render_success(@groups)
    end

    # GET /alusters/:cluster_id/consumer_groups/:id
    def show
      @cluster = Cluster.find(params[:cluster_id])
      @group = @cluster.groups.find { |g| g.group_id == params[:id] }

      if @group.nil?
        render_error('Consumer group not found', status: 404)
        return
      end

      @current_topic =
        if params[:topic]
          @group.consumed_topics.find { |t| t.name == params[:topic] }
        else
          @group.consumed_topics.first
        end

      render_success(@group)
    end
  end
end
