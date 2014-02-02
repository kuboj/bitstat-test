module Bitstat
  module DataProviders
    class Free
      include Bitlogger::Loggable

      def initialize(options)
        @node_id = options.fetch(:node_id)
        @vpss    = {}
      end

      def regenerate
        @vpss = []

        parsed = parse_output(get_free_output)
        @vpss << parsed unless parsed.nil?
      end

      def command
        "free -m"
      end

      def parse_output(output)
        {
            :veid      => @node_id,
            :physpages => output.split("\n")[2].split[2].to_i
        }
      end

      def get_free_output
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