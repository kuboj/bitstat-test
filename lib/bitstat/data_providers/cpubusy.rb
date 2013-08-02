module Bitstat
  module DataProviders
    class Cpubusy
      include Bitlogger::Loggable

      def initialize(vestat)
        raise ArgumentError, 'Vestat instance expected' unless vestat.kind_of?(Vestat)
        @vestat = vestat
        @vpss   = {}
        @diff   = {}
      end

      def regenerate
        @vestat.regenerate
        new_data = @vestat.vpss
        @diff = calculate_diff(new_data, @vpss) unless @vpss.empty?
        @vpss = new_data
      end

      def calculate_diff(vpss, vpss2)
        out = {}
        vpss.each do |veid, data|
          if vpss2.has_key?(veid)
            old_data = vpss2[veid]
            new_data = {}
            data.each { |k, v| new_data[k] = v - old_data[k] }
            out[veid] = new_data
          else
            out[veid] = data
          end
        end

        out
      end

      def each_vps(&block)
        @diff.each { |vps_id, diff| block.call({
                                                   :veid    => vps_id,
                                                   :cpubusy => calculate_load(diff)
                                               })
                   }
      end

      def calculate_load(data)
        l = 100.0 - data[:idle] * 100.0 / (100.0**3 * (data[:user] + data[:nice] + data[:system]) + data[:idle])
        if l.nan?
          warn("Calculate load - NaN. idle=#{data[:idle]} user=#{data[:user]} nice=#{data[:nice]} system=#{data[:system]}")
          0
        else
          l.to_i
        end
      end

      # Returns hash of vpss indexed by vps id. Each vps is represented
      # by hash with only one key - :cpubusy. Note that :cpubusy is calculated
      # via diff of underlying values from Vestat, therefore two calls of
      # #regenerate are required to get :cpubusy values
      #
      # NOTE: it is important that each data provider yields it's values under
      #       unique key in `out` hash (e.g. :cpubusy here)
      #
      # @example
      # cpubusy = Cpubusy.new(Vestat.new({ :path => '/proc/vz/vestat' }))
      # cpubusy.vpss
      # -> {}
      # cpubusy.regenerate
      # -> {}
      # cpubusy.regenerate
      # cpubusy.vpss
      # -> {
      #        13 => {
      #           :cpubusy => 19
      #        },
      #        18 => {
      #           :cpubusy => 
      #        }
      #    }
      #
      # @returns [Hash]
      def vpss
        out = {}
        @diff.each { |vps_id, diff| out[vps_id] = { :cpubusy => calculate_load(diff) } }
        out
      end
    end
  end
end