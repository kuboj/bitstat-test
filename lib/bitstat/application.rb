module Bitstat
  class Application
    include Bitlogger::Loggable

    def initialize(options)
      @vestat_path            = options.fetch(:vestat_path)
      @vzlist_fields          = options.fetch(:vzlist_fields)
      @filesystem_prefix      = options.fetch(:filesystem_prefix)
      @enabled_data_providers = options.fetch(:enabled_data_providers)
      @nodes_config_path      = options.fetch(:nodes_config_path)
      @resources_path         = options.fetch(:resources_path)
      @ticker_interval        = options.fetch(:ticker_interval)
      @supervisor_url         = options.fetch(:supervisor_url)
      @verify_ssl             = options.fetch(:verify_ssl)
      @node_id                = options.fetch(:node_id)
      @crt_path               = options.fetch(:crt_path,    nil)
      @max_retries            = options.fetch(:max_retries, nil)
      @wait_time              = options.fetch(:wait_time,   nil)
    end

    def start
      debug('Application: start')
      set_data_providers
      ticker.start { collector_thread.signal }
    end

    def stop
      debug('Application: stop')
      ticker.stop
      ticker.join
    end

    def stop!
      debug('Application: stop!')
      ticker.stop!
      ticker.join
    end

    def reload
      debug('Application: reload')
      nodes_diff = nodes_config.reload
      nodes_diff[:new].each do |id, node_config|
        create_node(id, node_config)
        collector.set_observer(id, nodes[id])
      end

      nodes_diff[:modified].each do |id, config_diff|
        nodes[id].reload(config_diff)
      end

      nodes_diff[:deleted].each_key do |id|
        delete_node(id)
        collector.delete_observer(id)
      end
    end

    def node_info(node_id)
      # TODO
    end

    def step
      collector.regenerate
      collector.notify_all
      notify_queue.flush
    end

    def join
      ticker.join
    end

    private
    def set_data_providers
      @enabled_data_providers.each do |dp|
        collector.set_data_provider(dp.to_sym, self.__send__(dp.to_sym))
      end
    end

    def create_node(id, config)
      debug("Creating node #{id}")
      nodes[id] = SynchronizedProxy.new(Node.new(
                                            :id              => id,
                                            :watchers_config => config,
                                            :notify_queue    => notify_queue
                                        ))
    end

    def delete_node(id)
      debug("Deleting node #{id}")
      nodes.delete(id)
    end

    def collector
      @collector ||= SynchronizedProxy.new(Collector.new)
    end

    def ticker
      @ticker ||= Ticker.new(@ticker_interval)
    end

    def vzlist
      @vzlist ||= DataProviders::Vzlist.new(:fields => @vzlist_fields)
    end

    def zfs_diskspace
      @zfs_diskspace ||= DataProviders::ZfsDiskspace.new(:filesystem_prefix => @filesystem_prefix)
    end

    def vestat
      @vestat ||= DataProviders::Vestat.new(:path => @vestat_path)
    end

    def cpubusy
      @cpubusy ||= DataProviders::Cpubusy.new(vestat)
    end

    def physpages
      @physpages ||= DataProviders::Physpages.new(:resources_path => @resources_path)
    end

    def mpstat
      @mpstat ||= DataProviders::Mpstat.new(:node_id => @node_id)
    end

    def free
      @free ||= DataProviders::Free.new(:node_id => @node_id)
    end

    def zfs_total_diskspace
      @free ||= DataProviders::ZfsTotalDiskspace.new(:node_id => @node_id)
    end

    def nodes_config
      @nodes_config ||= NodesConfig.new(:path => @nodes_config_path)
    end

    def nodes
      @nodes ||= SynchronizedProxy.new({})
    end

    def collector_thread
      @collector_thread ||= SignalThread.new { step }
    end

    def notify_queue
      @notify_queue ||= NotifyQueue.new(
          :sender  => sender,
          :node_id => @node_id
      )
    end

    def sender
      options = {
          :url        => @supervisor_url,
          :verify_ssl => @verify_ssl
      }
      options[:wait_time]   = @wait_time   if @wait_time
      options[:max_retries] = @max_retries if @max_retries
      options[:crt_path]    = @crt_path    if @crt_path
      @sender ||= Bitstat::Sender.new(options)
    end
  end
end