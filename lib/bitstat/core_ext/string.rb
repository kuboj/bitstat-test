class String
  def to_megabytes
    unit = self[-1, 1]
    num  = self[0..-2].to_f

    case unit
      when 'T' then "#{(num * 1024 * 1024)}M"
      when 'G' then "#{(num * 1024)}M"
      when 'M' then self
      else nil
    end
  end
end