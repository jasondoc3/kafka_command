module ConsumerGroupHelper

  def status_color(group)
    if group.empty?
      'has-text-info'
    elsif group.stable?
      'has-text-success'
    end
  end
end
