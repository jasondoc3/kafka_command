module ApplicationHelper
  def format_flash_errors
    return '' if flash[:error].blank?
    return flash[:error] if flash[:error].is_a?(String)

    '<ul>'.tap do |str|
      flash[:error].each do |k, v|
        str << "<li><span class='has-text-weight-bold'>#{k.humanize}:</span> #{v.join('. ')}</li>"
      end
    end.html_safe
  end

  def topic_path(topic)
    "#{cluster_path(@cluster)}/topics/#{URI.escape(topic.name)}"
  end

  def consumer_groups_path(group)
    "#{cluster_path(@cluster)}/consumer_groups/#{URI.escape(group.group_id)}"
  end

  def trim_name(name)
    return name if name.length < 25
    name[0..22] + '...'
  end
end
