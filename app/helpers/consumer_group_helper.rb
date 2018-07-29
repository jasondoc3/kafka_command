module ConsumerGroupHelper
  def consumer_groups_path(group)
    "#{cluster_path(@cluster)}/consumer_groups/#{group.group_id}"
  end

  def status_color(group)
    if group.empty?
      'has-text-info'
    elsif group.stable?
      'has-text-success'
    end
  end
end
