module Bitstat
  class Application
    include Bitlogger::Loggable

    # TODO: collector.synchronize { ... }

    def initialize(options)
      @options = options
      @vestat_path       = options.fetch(:vestat_path)
      @vzlist_fields     = options.fetch(:vzlist_fields)
      @nodes_config_path = options.fetch(:nodes_config_path)
      @nodes             = {}
    end

    def start
      collector.set_data_provider(:vzlist,  vzlist)
      collector.set_data_provider(:cpubusy, cpubusy)
      ticker.start { collector_thread.signal }
    end

    def stop
      ticker.stop
    end

    def info(data)
      #
    end

    def reload
      nodes = nodes_config.reload
      nodes[:new].each do |id, node_config|
        create_node(id, node_config)
        collector.set_observer(id, @nodes[id])
      end

      nodes[:modified].each do |id, config_diff|
        @nodes[id].reload(config_diff)
      end

      nodes[:deleted].each_key do |id|
        delete_node(id)
        collector.delete_observer(id)
      end
    end

    def create_node(id, config)
      @node[id] = Node.new(:watchers_config => config)
    end

    def delete_node(id)
      @node.delete(id)
    end

    private
    def collector
      @collector ||= Collector.new.extend(MonitorMixin)
    end

    def ticker
      @ticker ||= Ticker.new
    end

    def vzlist
      @vzlist ||= Vzlist.new(:fields => @vzlist_fields)
    end

    def vestat
      @vestat ||= Vestat.new(:path => @vestat_path)
    end

    def cpubusy
      @cpubusy ||= Cpubusy.new(vestat)
    end

    def nodes_config
      @nodes_config ||= NodesConfig.new(:path => @nodes_config_path)
    end

    def collector_thread
      @collector_thread ||= SignalThread.new do
        collector.regenerate
        collector.notify_all
      end
    end
  end
end