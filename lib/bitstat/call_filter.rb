module Bitstat
  module CallFilter
    def call_only_each(method, interval_var = :@interval, retval = false)
      original_method = "orig_#{method}"
      call_count      = "@__#{method}_count"
      interval_str    = "#{interval_var}"               # e.g "@interval"
      interval_sym    = "#{interval_str[1..-1]}".to_sym # e.g :interval

      class_eval { attr_accessor interval_sym }
      class_eval { alias_method original_method.to_sym, method.to_sym }

      class_eval(<<-EOS, "(__CALLFILTER__), 1")
        def #{method}(*args, &block)
          #{call_count} ||= 0
          retval = #{call_count}.zero? ? #{original_method}(*args, &block) : #{retval}
          #{call_count} = (#{call_count} + 1) % #{interval_str}

          retval
        end
      EOS
    end
  end
end