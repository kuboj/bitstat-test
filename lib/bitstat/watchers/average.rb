module Bitstat
  module Watchers
    class Average
      attr_accessor :interval, :count

      def initialize(params)
        @interval = params.fetch(:interval)
        @count    = params.fetch(:count)
        @sum      = 0
      end
    end
  end
end