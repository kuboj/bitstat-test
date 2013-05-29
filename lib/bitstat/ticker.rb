module Bitstat
  class Ticker
    include Bitlogger::Loggable

    def initialize(interval)
      @interval = interval
    end

    def start(&block)
      @thread = Thread.new do
        loop do
          debug("Tick, #{Time.now.to_f}")
          block.call
          sleep(@interval)
        end
      end
    end

    def stop
      @thread.kill if @thread.alive?
    end
  end
end