module Bitstat
  class Collector
    include Bitlogger::Loggable
    include Observable

    def initialize
      @data_providers = {}
    end

    def set_data_provider(label, provider)
      @data_providers[label] = provider
    end

    def regenerate
      @data_providers.values.map(&:regenerate)
      changed
    end

    def get_data
      out = {}
      @data_providers.each_value do |provider|
        provider.vpss.each do |veid, vps_data|
          out[veid] = out.fetch(veid, {}).merge(vps_data)
        end
      end

      out
    end

    def notify_all
      notify_observers(get_data)
    end

    # TODO: reimplement observable pattern -> observers (Hash) indexed by node_id
  end
end