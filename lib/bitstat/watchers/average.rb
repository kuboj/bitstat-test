module Bitstat
  module Watchers
    class Average
      include Bitlogger::Loggable
      extend CallFilter

      # each :interval call of #update will be taken, otherwise value dropped
      attr_accessor :interval

      # :count values have to be taken from #update until some average value
      # via #value can be provided
      attr_accessor :exceed_count

      def initialize(params)
        @interval            = params.fetch(:interval)
        @exceed_count        = params.fetch(:exceed_count)
        @sum                 = 0
        @values_count        = 0
      end

      def update(value)
        @sum          += value
        @values_count += 1
      end
      call_only_each(:update, :@interval)

      def notify?
        @values_count >= @exceed_count
      end

      def value
        @values_count.zero? ? 0 : (@sum / @values_count)
      end

      def reset
        @sum          = 0
        @values_count = 0
      end
    end
  end
end