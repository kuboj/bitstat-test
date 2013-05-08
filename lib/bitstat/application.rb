module Bitstat
  class Application
    include Bitlogger::Loggable

    # TODO: collector.synchronize { ... }

    def initialize(options)
      @options = options
      @vestat_path   = options.fetch(:vestat_path)
      @vzlist_fields = options.fetch(:vzlist_fields)
    end

    def start
      collector.synchronize { set_data_provider(:vzlist,  vzlist) }
      collector.set_data_provider(:cpubusy, cpubusy)
      ticker.start do
        collector.regenerate
        collector.notify_all
      end
    end

    def stop
      ticker.stop
    end

    def reload
      new, removed = @nodes.reload
      new.each { |node| collector.set_data_provider(node.id, node) }
      removed.each { |node| collector.delete_observer(node.id) }
    end

    def info(data)

    end

    private
    def nodes
      @nodes ||= Nodes.new(@nodes_path)
    end

    def collector
      if @collector.nil?
        @collector = Collector.new
        @collector.extend(MonitorMixin)
      else
        @collector
      end
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
  end
end