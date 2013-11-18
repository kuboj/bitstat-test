module Bitstat
  class CLI
    def initialize(args)
      options = default_options.merge(parse!(args))
      config  = load_config(options[:config_path])

      @options = default_options.merge(config).merge(options)
    end

    def run
      $DEBUG = @options[:devel][:debug]

      $0 = 'bitstat'
      daemonize if @options[:daemon]
      initialize_exit_handler
      initialize_bitlogger
      setup_signals
      application.start
      write_pid
      application.reload
      application.join
    ensure
      delete_pid
    end

    def load_config(path)
      YAML.load_file(path).symbolize_string_keys
    end

    def default_options
      {
          :config_path       => "#{APP_DIR}/config/config.yml",
          :daemon            => false,
          :crash_log_path    => "#{APP_DIR}/log/crash.log",
          :nodes_config_path => "#{APP_DIR}/config/nodes.yml",
          :app_name          => 'bitstat',
          :pid_path          => "#{APP_DIR}/pid/bitstat.pid"
      }
    end

    def parse!(args)
      options = {}

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: bitstat [options]'
        opts.separator "\nOptions:"

        opts.on('-c', "--config FILE", "Path to config file (default: config/config.yml)") do |config_path|
          options[:config_path] = File.expand_path("#{Dir.getwd}/#{config_path}") # TODO
        end

        opts.on('-d', "--daemon", "Daemonize (default: #{default_options[:daemon]})") do |daemon|
          options[:daemon] = daemon ? true : false
        end

        opts.on('-p', '--pid PATH', "File to store pid to (default: pid/bitstat.pid)") do |pid_path|
          options[:pid_path] = pid_path
        end

        opts.on_tail('-h','--help', 'Show this message') do
          puts opts
          exit
        end

        opts.on_tail('-v', '--version', 'Show version') do
          s = "Bitstat #{Bitstat::VERSION}"
          s << " (build: #{Bitstat::BUILD})" if defined?(Bitstat::BUILD)
          puts s
          exit
        end
      end

      begin
        opt_parser.parse!(args)
      rescue OptionParser::InvalidArgument, OptionParser::InvalidOption => e
        puts e.message
        abort(opt_parser.to_s)
      end

      options
    end

    #def send_to_controller(action, options = {})
    #  $DEBUG = @options[:devel][:debug]
    #  Bitlogger.init({
    #      :level  => :debug,
    #      :target => STDERR
    #  })
    #  self.extend(Bitlogger::Loggable)
    #  debug("Sending #{action} to controller")
    #  controller_request = { :request => (options.merge(:action => action)).to_json }
    #  retval = sender.send_data(controller_request)
    #  abort("Error while #{action}") if retval.nil?
    #rescue => e
    #  error(e)
    #  abort(1)
    #end

    #def controller
    #  @controller ||= Controller.new(
    #      :port                => @options[:bitstat][:port],
    #      :app_class           => Bitstat::SinatraApp,
    #      :application_options => {
    #          :vestat_path            => @options[:bitstat][:vestat_path],
    #          :vzlist_fields          => @options[:bitstat][:vzlist_fields],
    #          :filesystem_prefix      => @options[:bitstat][:filesystem_prefix],
    #          :enabled_data_providers => @options[:bitstat][:enabled_data_providers],
    #          :nodes_config_path      => @options[:nodes_config_path],
    #          :resources_path         => @options[:bitstat][:resources_path],
    #          :ticker_interval        => @options[:bitstat][:tick],
    #          :supervisor_url         => @options[:bitsuper][:url],
    #          :verify_ssl             => @options[:bitsuper][:verify_crt],
    #          :node_id                => @options[:bitstat][:node_id],
    #          :crt_path               => @options[:bitsuper][:verify_crt] ? @options[:bitsuper][:ca_crt_path] : nil
    #      }
    #  )
    #end

    def application
      @application ||= Application.new(
          :vestat_path            => @options[:bitstat][:vestat_path],
          :vzlist_fields          => @options[:bitstat][:vzlist_fields],
          :filesystem_prefix      => @options[:bitstat][:filesystem_prefix],
          :enabled_data_providers => @options[:bitstat][:enabled_data_providers],
          :nodes_config_path      => @options[:nodes_config_path],
          :resources_path         => @options[:bitstat][:resources_path],
          :ticker_interval        => @options[:bitstat][:tick],
          :supervisor_url         => @options[:bitsuper][:url],
          :verify_ssl             => @options[:bitsuper][:verify_crt],
          :node_id                => @options[:bitstat][:node_id],
          :crt_path               => @options[:bitsuper][:verify_crt] ? @options[:bitsuper][:ca_crt_path] : nil
      )
    end

    #def sender
    #  @sender ||= Sender.new(:url => "http://localhost:#{@options[:bitstat][:port]}")
    #end

    #def initialize_term_handler
    #  Signal.trap('TERM') { controller.stop }
    #  Signal.trap('INT')  { controller.stop }
    #end

    def daemonize
      if RUBY_VERSION < '1.9'
        exit if fork
        Process.setsid
        exit if fork
        Dir.chdir('/')
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen('/dev/null', 'a')
      else
        Process.daemon
      end
    end

    def write_pid
      FileUtils.mkdir_p(File.dirname(@options[:pid_path]))
      File.open(@options[:pid_path], 'w+') { |f| f.write(Process.pid) }
    end

    def delete_pid
      FileUtils.rm_rf(@options[:pid_path])
    end

    def setup_signals
      Signal.trap('TERM')   { application.stop }
      Signal.trap('INT')    { application.stop }
      Signal.trap('SIGHUP') { application.reload }
    end

    def initialize_bitlogger
      loggers_config = if @options[:logging].is_a?(Hash)
                         [@options[:logging]]
                       elsif @options[:logging].is_a?(Array)
                         @options[:logging]
                       end
      loggers_config.map! do |logger_config|
        if logger_config[:target] == 'supervisor'
          logger_config[:target]      = @options[:bitsuper][:url].gsub('/notify', '/logs')
          logger_config[:buffered]    = true
          logger_config[:ca_crt_path] = @options[:bitsuper][:ca_crt_path]
        end
        logger_config[:additional] = { :hostname => `hostname`.strip }
        logger_config
      end

      Bitlogger.init(loggers_config)
      self.extend(Bitlogger::Loggable)
    end

    def initialize_exit_handler
      at_exit do
        if $! && $!.class != SystemExit # if exception was thrown
          log_dir = File.dirname(@options[:crash_log_path])
          FileUtils.mkdir_p(log_dir) unless File.exists?(log_dir)
          open(@options[:crash_log_path], 'a')  do |log|
            error = {
                :timestamp => Time.now,
                :error     => $!.class.name,
                :message   => $!.message,
                :backtrace => $!.backtrace
            }
            YAML.dump(error, log)
          end
        end
      end
    end
  end
end