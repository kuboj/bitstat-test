module Bitstat
  class SignalThread
    def initialize(&block)
      @signal = false
      @thread = Thread.new(block) do |b|
        loop do
          Thread.stop until @signal
          @signal = false
          b.call
        end
      end
    end

    def signal
      @signal = true
      @thread.run
    end
  end
end