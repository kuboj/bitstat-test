module Bitstat
  class Ticker
    include Bitlogger::Loggable

    def initialize(interval)
      @interval = interval
      @stop     = false
    end

    def start(&block)
      @thread = Thread.new do
        until @stop
          debug("Tick, #{Time.now.to_f}")
          block.call
          sleep(@interval)
        end
      end
    end

    def stop
      @stop = true
    end

    def stop!
      @thread.kill if @thread.alive?
    end

    def join
      @thread.join if @thread.alive?
    end
  end
end