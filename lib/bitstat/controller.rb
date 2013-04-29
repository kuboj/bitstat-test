module Bitstat
  class Controller
    include Bitlogger::Loggable
    extend Forwardable

    DAEMONS_COMMANDS = %w(start stop restart status)
    CUSTOM_COMMANDS  = %w(info reload)
    def_delegators :application, *CUSTOM_COMMANDS

    def initialize(options)
      @options = options
      @port    = @options.fetch(:port)
    end

    def start
      server.start
      application.start
    end

    def stop
      server.stop
      application.stop
    end

    private
    def server
      @server ||= HttpServer.new(:app_class => Bitstat::SinatraApp,
                                 :port      => @port,
                                 :callback  => Proc.new { |params| on_request(params) })
    end

    def application
      @application ||= Application.new({}) # TODO
    end

    def on_request(params)
      params = params.symbolize_string_keys
      action = params.delete(:action)
      (self.send(action.to_sym, params)).to_json
    rescue => e
      { :code => -1, :message => "#{e.class}: #{e.message}" }
    end
  end
end