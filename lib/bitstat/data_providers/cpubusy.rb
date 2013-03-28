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

      def regenerate!
        @vestat.regenerate!
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
        100.0 - data[:idle] * 100.0 / (100.0**3 * (data[:user] + data[:nice] + data[:system]) + data[:idle])
      end

      def vpss
        out = {}
        @diff.each { |vps_id, diff| out[vps_id] = { :cpubusy => calculate_load(diff) } }
        out
      end
    end
  end
end