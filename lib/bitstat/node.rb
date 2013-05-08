module Bitstat
  class Node
    include Bitlogger::Loggable

    def initialize(options)
      @id         = options.fetch(:id)
      @config     = {}
      @watchers   = {}
    end

    def reload(new_config)
      @config = new_config

      @config.each do |parameter, watchers_diff|
        watchers_diff[:new].each do |type, watcher_config|
          (@watchers[parameter] ||= {})[type] = get_new_watcher(type, watcher_config)
        end
      end

      parameters = @config.keys | @old_config.keys
      parameters.each do |parameter| # :cpubusy, :diskinodes, ...
        watcher_types = @config[parameter].keys | @old_config[parameter].keys
        watcher_types.each do |type| # :up, :down, :average, ...
          if @config.has_key?(parameter)
      #      @config[parameter][type] ==
          end
        end
      end


      @config.each do |parameter, watchers|
        watchers.each do |type, watcher_config|

        end
      end
    end

    def update(data)
      @watchers.each do |parameter, specific_watchers|
        specific_watchers.each_value do |watcher|
          watcher.update(data[parameter])
        end
      end
    end

    #private
    def watcher_config_diff(config1, config2)

    end

    def get_new_watcher(type, config)
      Bitstat::Watchers.const_get(type.to_s.capitalize.cam)
    end
  end
end