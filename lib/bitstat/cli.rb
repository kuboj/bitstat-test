module Bitstat
  class CLI
    DAEMONS_COMMANDS = %w(start stop restart status)
    CUSTOM_COMMANDS  = %w(info get_vps_data)
    APP_NAME = 'bitstatd'

    def initialize(argv)
      parse_argv
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

    end

    def run_daemons(command)
      daemon_options = {
          :dir_mode            => :normal,
          :dir                 => @pid_dir,
          :multiple            => false,
          :force_kill_waittime => @force_kill_waittime,
          :ARGV                => [command]
      }

      Daemons.run_proc(APP_NAME, daemon_options) { controller.start }
    end

    def send_to_controller(command, data)
      response = RestClient.post("http://localhost:#@port/", (data).merge(:action => command))
      puts response
    end

    def controller
      @controller ||= Controllew.new()
    end
  end
end