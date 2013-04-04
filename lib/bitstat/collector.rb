module Bitstat
  class Collector
    include Bitlogger::Loggable

    def initialize
      @data_providers = {}
      @observers      = {}
    end

    def set_data_provider(label, provider)
      @data_providers[label] = provider
    end

    def delete_data_provider(label)
      @data_providers.delete(label)
    end

    def regenerate
      @data_providers.values.map(&:regenerate)
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

    def set_observer(id, observer)
      @observers[id] = observer
    end

    def delete_observer(id)
      @observers.delete(id)
    end

    def notify_observers(data)
      @observers.values.each { |observer| observer.update(data) }
    end
  end
end