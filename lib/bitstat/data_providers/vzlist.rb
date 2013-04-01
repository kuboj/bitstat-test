module Bitstat
  module DataProviders
    class Vzlist
      include Bitlogger::Loggable

      def initialize(options)
        # TODO: add check for :fields based on vzctl version
        @fields = (%w(veid) | options.fetch(:fields)).map!(&:to_sym)
        @vpss   = []
      end

      def regenerate!
        @vpss = []
        get_vzlist_output.each_line { |l| @vpss << parse_line(l) }
      end

      def command
        "vzlist -Hto #{@fields.join(',')}"
      end

      def parse_line(line)
        Hash[@fields.zip(line.split(' '))]
      end

      def get_vzlist_output
        `#{command}`
      end

      def each_vps(&block)
        @vpss.each { |vps| block.call(vps) }
      end

      # Returns hash of vpss indexed by vps id. Each vps is represented
      # by hash with keys given as :fields in constructor method.
      #
      # @example
      # vzlist = Vzlist.new({ :fields => ['physpages', 'diskinodes'] })
      # vzlist.vpss
      # -> {}
      # vzlist.regenerate!
      # vzlist.vpss
      # -> {
      #        13 => {
      #           :physpages  => 4144,
      #           :diskinodes => 24225,
      #        },
      #        18 => {
      #           :physpages  => 12512,
      #           :diskinodes => 23509,
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