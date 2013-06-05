module Bitstat
  module Watchers
    class Up
      include Bitlogger::Loggable
      extend CallFilter

      attr_accessor :threshold, :exceed_count, :interval, :aging

      def initialize(params)
        @threshold    = params.fetch(:threshold)
        @exceed_count = params.fetch(:exceed_count)
        @interval     = params.fetch(:interval)
        @aging        = params.fetch(:aging)
        @count        = 0
        @last_value   = nil
      end

      def update(value)
        @last_value = value
        @count += 1 if @last_value >= @threshold
      end
      call_only_each(:update, :@interval)

      def notify?
        @count >= @exceed_count
      end

      def value
        @last_value
      end

      def reset
        @count = 0
      end

      def age
        @count = [0, @count - @aging].max
      end
    end
  end
end