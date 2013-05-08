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
            modified[id] = config1[id]
          end
        elsif config1.has_key?(id) && !config2.has_key?(id)
          new[id] = config1[id]
        elsif !config1.has_key?(id) && config2.has_key?(id)
          deleted[id] = config2[id]
        end
      end

      [new, modified, deleted]
    end
  end
end