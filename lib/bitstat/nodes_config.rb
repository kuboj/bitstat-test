module Bitstat
  class NodesConfig
    include Bitlogger::Loggable
    include MonitorMixin

    def initialize(options)
      @options    = options
      @path       = options.fetch(:path)
      @old_config = {}
      @config     = {}
    end

    def reload
      self.synchronize do
        @old_config = @config
        File.open(@path) do |f|
          debug("Trying to acquire file lock. PID=#{Process.pid}, Thread=#{Thread.current.inspect}.")
          f.flock(File::LOCK_EX)
          debug("Lock acquired. PID=#{Process.pid}, Thread=#{Thread.current.inspect}.")
          @config = YAML::load(f).symbolize_string_keys
          debug("Unlocking file. PID=#{Process.pid}, Thread=#{Thread.current.inspect}.")
          f.flock(File::LOCK_UN)
          debug("File unlocked. PID=#{Process.pid}, Thread=#{Thread.current.inspect}.")
        end

        diff(@config, @old_config)
      end
    end

    def diff(config1, config2)
      new      = {}
      modified = {}
      deleted  = {}
      ids      = config1.keys | config2.keys
      ids.each do |id|
        if config1.has_key?(id) && config2.has_key?(id)
          if config1[id] != config2[id]
            modified[id] = watchers_diff(config1[id], config2[id])
          end
        elsif config1.has_key?(id) && !config2.has_key?(id)
          new[id] = config1[id]
        elsif !config1.has_key?(id) && config2.has_key?(id)
          deleted[id] = config2[id]
        end
      end

      {
          :new      => new,
          :modified => modified,
          :deleted  => deleted
      }
    end

    def watchers_diff(config1, config2)
      out = { :new => {}, :deleted => {} }
      parameters    = config1.keys | config2.keys
      # this return array of unique keys of configs from second level of nesting,
      # e.g. [:average, :up, :down]
      watcher_types = [config1, config2].map(&:values).flatten.map(&:keys).flatten.uniq

      parameters.each do |parameter|
        if config1.has_key?(parameter) && config2.has_key?(parameter)
          # both config have this key (e.g. :cpubusy), so we now know, that
          # these watchers might have changes.
          watcher_types.each do |watcher_type|
            if config1[parameter].has_key?(watcher_type) && config2[parameter].has_key?(watcher_type)
              unless config1[parameter][watcher_type] == config2[parameter][watcher_type]
                (out[:new][parameter] ||= {})[watcher_type] = config1[parameter][watcher_type]
                (out[:deleted][parameter] ||= {})[watcher_type] = config2[parameter][watcher_type]
              end
            elsif config1[parameter].has_key?(watcher_type) && !config2[parameter].has_key?(watcher_type)
              (out[:new][parameter] ||= {})[watcher_type] = config1[parameter][watcher_type]
            elsif !config1[parameter].has_key?(watcher_type) && config2[parameter].has_key?(watcher_type)
              (out[:deleted][parameter] ||= {})[watcher_type] = config2[parameter][watcher_type]
            end
          end
        elsif config1.has_key?(parameter) && !config2.has_key?(parameter)
          out[:new][parameter] = config1[parameter]
        elsif !config1.has_key?(parameter) && config2.has_key?(parameter)
          out[:deleted][parameter] = config2[parameter]
        end
      end

      out
    end
  end
end