module ClustersHelper
  def tab_class(tab_name)
    return 'is-active' if controller_name == tab_name
  end
end
