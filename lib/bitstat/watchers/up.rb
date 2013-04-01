module Bitstat
  module Watchers
    class Up
      attr_accessor :threshold, :exceed_count, :interval, :aging

      def initialize(params)
        @threshold    = params.fetch(:threshold)
        @exceed_count = params.fetch(:exceed_count)
        @interval     = params.fetch(:interval)
        @aging        = params.fetch(:aging)
        @count        = 0
        @last_value   = nil
      end
    end
  end
end