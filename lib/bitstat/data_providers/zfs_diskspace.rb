module Bitstat
  module DataProviders
    class ZfsDiskspace
      include Bitlogger::Loggable

      def initialize(options)
        @filesystem_prefix = options.fetch(:filesystem_prefix)
        @vpss              = {}
      end

      def regenerate
        @vpss = []
        get_zfs_get_output.each_line do |l|
          parsed = parse_line(l)
          @vpss << parsed unless parsed.nil?
        end
      end

      def command
        "zfs get -H -p used -t filesystem -o name,value"
      end

      def get_zfs_get_output
        `#{command}`
      end

      def parse_line(line)
        filesystem, value = line.strip.split(' ').map(&:strip)
        if filesystem.start_with?(@filesystem_prefix)
          {
              :veid      => filesystem.gsub(@filesystem_prefix, '').to_i,
              :diskspace => bytes_to_megabytes(value.to_i)
          }
        else
          nil
        end
      rescue => e
        error("Error while parsing line '#{line}'", e)
        nil
      end

      def each_vps(&block)
        @vpss.each { |vps| block.call(vps) }
      end

      def vpss
        # returns hash of vpss indexed by veid and deletes veid from vps data
        @vpss.inject({}) { |out, vps| out[vps[:veid].to_i] = vps.reject { |k, _| k == :veid } ; out }
      end

      private
      def bytes_to_megabytes(v)
        v / 1024 / 1024
      end
    end
  end
end