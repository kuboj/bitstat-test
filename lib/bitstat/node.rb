module Bitstat
  class Node
    include Bitlogger::Loggable
    attr_reader :watchers

    # TODO: this class must be synchronized!

    def initialize(options)
      @id       = options.fetch(:id)
      @watchers = {}
      create_watchers(options.fetch(:watchers_config))
    end

    def reload(config)
      delete_watchers(config[:deleted])
      create_watchers(config[:new])
    end

    def update(data)
      @watchers.each do |parameter, watchers|
        watchers.each_value do |watcher|
          if data[parameter]
            watcher.update(data[parameter])
          else
            warn("Node id=#@id, watcher #{parameter}:#{watcher.class.name}, data variable does not contain key for #{parameter}")
          end
        end
      end
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