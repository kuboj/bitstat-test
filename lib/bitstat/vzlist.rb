module Bitstat
  class Vzlist
    include Bitlogger::Loggable

    def initialize(options)
      @fields = (%w(veid) | options.fetch(:fields)).map!(&:to_sym)
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

    def vpss
      # returns hash of vpss indexed by veid and deletes veid from vps data
      @vpss.inject({}) { |out, vps| out[vps[:veid].to_i] = vps.reject { |k, _| k == :veid } ; out }
    end
  end
end