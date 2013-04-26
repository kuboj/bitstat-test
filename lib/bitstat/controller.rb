module Bitstat
  class Controller
    include Bitlogger::Loggable

    def initialize(options)
      @options = options
      @port    = @options.fetch(:port)
      Signal.trap('TERM') { application.stop }
    end

    def start
      start_server
      application.start
    end

    def stop
      stop_server
      application.stop
    end

    private
    def start_server
      @server = HttpServer.new(:app_class => Bitstat::SinatraApp,
                               :port      => @port,
                               :callback  => Proc.new { |params| on_request(params) })
      @server.start
    end

    def stop_server
      @server.stop
    end

    def application
      @application ||= Application.new(@app_options)
    end

    def on_request(params)
      action = params.delete('action')
      self.send(action.to_sym, params)
    end
  end
end