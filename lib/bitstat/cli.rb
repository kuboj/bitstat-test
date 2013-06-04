module Bitstat
  class CLI
    DAEMONS_COMMANDS = %w(start stop restart status run)
    CUSTOM_COMMANDS  = %w(node_info reload)
    COMMANDS = DAEMONS_COMMANDS + CUSTOM_COMMANDS

    def initialize(args)
      @options = default_options
      parse_args(args)
      @options = @options.merge(load_config(@options[:config_path]))
      $DEBUG = @options[:devel][:debug]
      initialize_bitlogger
      # initialize Application - therefore Thin and Sinatra will register their
      # SIGINT ant SIGTERM handlers so we can overwrite them
      controller.application
      initialize_term_handler
    end

    def default_options
      {
          :config_path       => "#{APP_DIR}/config/config.yml",
          :pid_dir           => "#{APP_DIR}/pid/",
          :nodes_config_path => "#{APP_DIR}/config/nodes.yml",
          :app_name          => 'bitstat'
      }
    end

    def load_config(path)
      config = YAML.load_file(path).symbolize_string_keys
      config[:logging][:level] = config[:logging][:level].to_sym
      config
    end

    def run
      if DAEMONS_COMMANDS.include?(@options[:command])
        run_daemons(@options[:command])
      elsif CUSTOM_COMMANDS.include?(@options[:command])
        send_to_controller(@options[:command], @data)
      end
    end

    def run_daemons(command)
      daemon_options = {
          :dir_mode            => :normal,
          :dir                 => @options[:pid_dir],
          :multiple            => false,
          :force_kill_waittime => @options[:bitstat][:force_kill_waittime],
          :ARGV                => [command]
      }

      Daemons.run_proc(@options[:app_name], daemon_options) { controller.start }
    end

    def send_to_controller(action, options = {})
      controller_request = { :request => (options.merge(:action => action)).to_json }
      sender.send_data(controller_request)
    end

    private
    def parse_args(args)
      OptionParser.new(&method(:set_opts)).parse!(args)
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption => e
      abort(e.message)
    end

    def set_opts(opts)
      opts.banner = 'Usage: bitstat [options] COMMAND'
      opts.define_head "Bitstat, version #{Bitstat::VERSION}"
      opts.separator "\nOptions:"

      opts.on("-f", "--config FILE", "Path to config file, defaults to #{default_options[:config_path]}") do |config_path|
        @options[:config_path] = config_path
        raise OptionParser::InvalidArgument, "File #{config_path} does not exist!" unless File.exists?(config_path)
      end

      opts.on_tail('-v', '--version', 'Print version') do
        puts "Bitstat #{Bitstat::VERSION}"
        exit
      end

      help = Proc.new do
        puts opts
        puts
        puts "COMMAND has to be one of #{COMMANDS.map { |s| "`#{s}`"}.join(',')}"
        exit
      end

      help.call if ARGV.empty?

      command = ARGV.pop
      if COMMANDS.include?(command)
        @options[:command] = command
      else
        raise OptionParser::InvalidArgument, "Unknown command #{command}"
      end

      opts.on_tail('-h','--help', 'Show this message', &help)
    end

    def controller
      @controller ||= Controller.new(
          :port                => @options[:port],
          :app_class           => Bitstat::SinatraApp,
          :application_options => {
              :vestat_path       => @options[:bitstat][:vestat_path],
              :vzlist_fields     => @options[:bitstat][:vzlist_fields],
              :nodes_config_path => @options[:nodes_config_path],
              :ticker_interval   => @options[:bitstat][:tick],
              :supervisor_url    => @options[:bitsuper][:url],
              :verify_ssl        => @options[:bitsuper][:verify_crt],
              :node_id           => @options[:bitstat][:node_id],
              :crt_path          => @options[:bitsuper][:verify_crt] ? @options[:bitsuper][:ca_crt_path] : nil
          }
      )
    end

    def sender
      @sender ||= Sender.new("http://localhost:#{@options[:port]}")
    end

    def initialize_term_handler
      Signal.trap('TERM') do
        debug('Got SIGTERM')
        controller.stop
      end

      Signal.trap('INT') do
        debug('Got SIGINT')
        controller.stop
      end
    end

    def initialize_bitlogger
      logging_options = {
          :level      => @options[:logging][:level],
          :additional => { :hostname => `hostname`.strip }
      }
      if @options[:logging][:target] == 'supervisor'
        logging_options[:target]      = "#{@options[:bitsuper][:url]}/logs"
        logging_options[:buffered]    = true
        logging_options[:ca_crt_path] = @options[:bitsuper][:ca_crt_path]
      else
        logging_options[:target] = @options[:logging][:target]
      end
      Bitlogger.init(logging_options)
    end
  end
end