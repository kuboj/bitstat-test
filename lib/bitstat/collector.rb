module Bitstat
  class Collector
    include Bitlogger::Loggable
    include Observable

    def initialize
      @data_providers = {}
    end

    def set_data_provider(provider)

    end

    def regenerate

    end
  end
end