module Bitstat
  class SignalThread
    def initialize(&block)
      @cv = ConditionVariable.new
      @m  = Mutex.new
      @thread = Thread.new(block) do |b|
        loop do
          @m.synchronize { @cv.wait(@m) }
          b.call
        end
      end
    end

    def signal
      @m.synchronize { @cv.signal }
    end
  end
end