module Bitstat
  class Node
    include Bitlogger::Loggable
    attr_reader :watchers

    def initialize(options)
      @id           = options.fetch(:id)
      @notify_queue = options.fetch(:notify_queue)
      @watchers     = {}
      debug("Creating node id=#{@id}")
      create_watchers(options.fetch(:watchers_config))
    end

    def reload(config)
      delete_watchers(config[:deleted]) if config[:deleted]
      create_watchers(config[:new])     if config[:new]
    end

    def update(data)
      if data.has_key?(@id)
        data = data[@id]
      else
        debug("Node id=#@id. data variable does not contain anything for this node.")
        return
      end

      @watchers.each do |parameter, watchers| # parameter can be for example :cpubusy or :physpages
        watchers.each do |watcher_type, watcher| # watcher type - e.g. :up, :down, ...
          if data[parameter]
            watcher.update(data[parameter])
            if watcher.notify?
              add_notification(parameter, watcher_type, watcher.value)
              watcher.reset
            end
          else
            warn("Node id=#@id, watcher #{parameter}:#{watcher.class.name}, data variable does not contain key for #{parameter} (keys: [#{data.keys.join(', ')}])")
          end
        end
      end
    end

    def add_notification(parameter, type, value)
      debug("Node id=#@id, notification. #{parameter}, #{type}, #{value}")
      @notify_queue << {
          :node_id      => @id,
          :parameter    => parameter,
          :watcher_type => type,
          :value        => value
      }
    end

    def delete_watchers(config)
      config.each do |parameter, watchers|
        watchers.each do |watcher_type, watcher_config|
          delete_watcher(parameter, watcher_type)
        end
      end
    end

    def create_watchers(config)
      config.each do |parameter, watchers|
        watchers.each do |watcher_type, watcher_config|
          create_watcher(parameter, watcher_type, watcher_config)
        end
      end
    end

    def delete_watcher(parameter, watcher_type)
      @watchers[parameter].delete(watcher_type)
      @watchers.delete(parameter) if @watchers[parameter].empty?
    end

    def create_watcher(parameter, watcher_type, watcher_config)
      (@watchers[parameter] ||= {})[watcher_type] = get_watcher_class(watcher_type).new(watcher_config)
    end

    def get_watcher_class(type)
      Bitstat::Watchers.const_get(type.to_s.capitalize.camelize)
    end
  end
end