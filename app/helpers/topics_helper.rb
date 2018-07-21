module TopicsHelper
  def topic_path(topic)
    "#{cluster_path(@cluster)}/topics/#{topic.name}"
  end
end
