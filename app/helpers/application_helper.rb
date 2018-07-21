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
end
