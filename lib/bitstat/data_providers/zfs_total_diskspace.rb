module Bitstat
  module DataProviders
    class ZfsTotalDiskspace
      include Bitlogger::Loggable

      def initialize(options)
        @filesystem = options.fetch(:filesystem, 'vz')
        @node_id    = options.fetch(:node_id)
        @vpss       = {}
      end

      def regenerate
        @vpss = []

        parsed = parse_output(get_zfs_output)
        @vpss << parsed unless parsed.nil?
      end

      def command
        "zfs list -H -o used #{@filesystem}"
      end

      def parse_output(output)
        {
            :veid      => @node_id,
            :diskspace => output.strip.to_megabytes[1..-2].to_i
        }
      end

      def get_zfs_output
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