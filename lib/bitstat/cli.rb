module Bitstat
  class CLI
    def initialize(argv)
      parse_argv
      initialize_term_handler
    end

    def run
      if DAEMONS_COMMANDS.include?(@command)
        run_daemons(@command)
      elsif CUSTOM_COMMANDS.include?(@command)
        send_to_controller(@command, @data)
      else
        abort("Unknown command `#@command`")
      end
    end

    def parse_argv
      #@app_name =
      #@pid_dir =
      #@force_kill_waittime =
      #@command =
      #@controller_options
      #@host
    end

    def run_daemons(command)
      daemon_options = {
          :dir_mode            => :normal,
          :dir                 => @pid_dir,
          :multiple            => false,
          :force_kill_waittime => @force_kill_waittime,
          :ARGV                => [command]
      }

      Daemons.run_proc(@app_name, daemon_options) { controller.start }
    end

    def send_to_controller(command, data = {})
      response_hash = sender.send((data).merge(:action => command))
      puts response
    end

    def controller
      @controller ||= Controllew.new(:port => @port)
    end

    def sender
      @sender ||= Sender.new(:port => @port, :host => @host)
    end

    def initialize_term_handler
      Signal.trap('TERM') { controller.stop }
    end
  end
end