module Bitstat
  module DataProviders
    class Vestat
      include Bitlogger::Loggable

      def initialize(options)
        @path = options.fetch(:path)
        @vpss = []
      end

      def regenerate
        @vpss = []
        get_vestat_output.each_line do |l|
          next if skip_line?(l)
          veid, user, nice, system, idle = parse_line(l)
          @vpss << {
              :veid   => veid,
              :user   => user,
              :nice   => nice,
              :system => system,
              :idle   => idle
          }
        end
      end

      def skip_line?(l)
        l.include?('Version') || l.include?('VEID')
      end

      def parse_line(l)
        veid, user, nice, system, _, idle = l.scan(/\d+/).map(&:to_i)
        [veid, user, nice, system, idle]
      end

      def get_vestat_output
        File.readlines(@path)
      end

      def each_vps(&block)
        @vpss.each { |vps| block.call(vps) }
      end

      # Returns hash of vpss indexed by vps id. Each vps is represented
      # by hash with keys :user, :nice, :system and :idle
      #
      # @example
      # vestat = Vestat.new({ :path => '/proc/vz/vestat' })
      # vestat.vps
      # -> {}
      # vestat.regenerate
      # vestat.vpss
      # -> {
      #        13 => {
      #           :user   => 224,
      #           :nice   => 42,
      #           :system => 34,
      #           :idle   => 24242424125,
      #        },
      #        18 => {
      #           :user   => 224,
      #           :nice   => 42,
      #           :system => 34,
      #           :idle   => 24242424125,
      #        }
      #    }
      #
      # @returns [Hash]
      def vpss
        # returns hash of vpss indexed by veid and deletes veid from vps data
        @vpss.inject({}) { |out, vps| out[vps[:veid].to_i] = vps.reject { |k, _| k == :veid } ; out }
      end
    end
  end
end