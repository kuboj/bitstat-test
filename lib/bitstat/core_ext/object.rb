class Object
  def symbolize_string_keys(visited = Set.new)
    if visited.include? self.object_id
      raise "Universe has just broken down, sad lolcat. #{self.to_yaml}"
    end

    if self.is_a?(Array)
      visited << self.object_id
      self.map { |a| a.symbolize_string_keys visited }
    elsif self.is_a?(Hash)
      visited << self.object_id
      self.inject({}) do |new_hash, (k, v)|
        new_hash[k.is_a?(String) ? k.to_sym : k] = v.symbolize_string_keys(visited)
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