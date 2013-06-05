class Object
  def symbolize_string_keys
    if self.is_a?(Array)
      self.map(&:symbolize_string_keys)
    elsif self.is_a?(Hash)
      self.inject({}) do |new_hash, (k, v)|
        new_hash[k.is_a?(String) ? k.to_sym : k] = v.symbolize_string_keys
        new_hash
      end
    else
      self
    end
  end

  def to_array
    self.is_a?(Array) ? self : [self]
  end
end