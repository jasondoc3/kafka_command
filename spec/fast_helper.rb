$LOAD_PATH.unshift(File.expand_path('.') + '/app/wrappers')

alias require_dependency require

# This is called in some "non-rails" code
class Hash
  def with_indifferent_access
    self
  end
end
