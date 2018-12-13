alias require_dependency require

# This is called in some "non-rails" code
class Hash
  def with_indifferent_access
    self
  end
end

class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    !blank?
  end
end
