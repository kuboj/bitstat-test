module Bitstat
  module DataProviders
    class Mpstat
      include Bitlogger::Loggable

      def initialize(options)
        @node_id = options.fetch(:node_id)
        @vpss    = []
      end

      def regenerate
        @vpss = []

        parsed = parse_line(get_mpstat_output)
        @vpss << parsed unless parsed.nil?
      end

      def command
        "cat /proc/stat | head -n1"
      end

      def parse_line(line)
        values    = line.split[1..-1].map(&:to_i)
        new_idle  = values[3]
        new_total = values.reduce(&:+)

        retval = if @old_idle.nil?
                   nil
                 else
                   idle_diff  = new_idle  - @old_idle
                   total_diff = new_total - @old_total
                   {
                       :veid    => @node_id,
                       :cpubusy => (100.0 * (total_diff - idle_diff) / total_diff)
                   }
                 end

        @old_idle  = new_idle
        @old_total = new_total

        return retval
      rescue => e
        error("Error while parsing line '#{line}'", e)
        nil
      end

      def get_mpstat_output
        `#{command}`
      end

      def each_vps(&block)
        @vpss.each { |vps| block.call(vps) }
      end

      def vpss
        # returns hash of vpss indexed by veid and deletes veid from vps data
        @vpss.inject({}) { |out, vps| out[vps[:veid].to_i] = vps.reject { |k, _| k == :veid } ; out }
      end
    end
  end
end