class TopicsController < ApplicationController
  rescue_from Kafka::InvalidPartitions, with: :invalid_partitions
  rescue_from Kafka::InvalidReplicationFactor, with: :invalid_replication_factor
  rescue_from Kafka::InvalidTopic, with: :invalid_topic

  # GET /clusters/:cluster_id/topics
  def index
    @cluster = Cluster.find(params[:cluster_id])
    @topics = @cluster.topics

    flash[:search] = params[:name]

    if params[:name].present?
      @topics =@topics.select do |t|
        regex = /#{params[:name]}/i
        t.name.match?(regex)
      end
    end

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

  # GET /clusters/:cluster_id/topics/new
  def new
    @cluster = Cluster.find(params[:cluster_id])
  end

  # POST /clusters/:cluster_id/topics
  def create
    @cluster = Cluster.find(params[:cluster_id])
    @topic = @cluster.create_topic(
      params[:name],
      num_partitions: params[:num_partitions].to_i,
      replication_factor: params[:replication_factor].to_i
    )

    render_success(
      @topic,
      status: :created,
      redirection_path: cluster_topics_path,
      flash: { success: 'Topic created' }
    )
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
