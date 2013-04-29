module Bitstat
  class HttpServer
    include Bitlogger::Loggable

    def initialize(options)
      @options    = options
      @port       = @options.fetch(:port)
      @app_class  = @options.fetch(:app_class)
      @callback   = @options.fetch(:callback)
    end

    def start
      @app_class.set_callback(@callback)
      info("HttpServer: starting sinatra application on port #@port")
      @thin_thread = Thread.new do
        Rack::Handler::Thin.run(@app_class, { :Port => @port }) do |server|
          @thin = server
          Thin::Logging.silent = true
        end
      end
      sleep(0.1) until @thin && @thin.running?

      @thin_thread
    end

    def stop
      debug('HttpServer: stop')
      @thin.stop unless @thin.running?
      @thin_thread.kill unless @thin_thread.nil? || @thin_thread.status
    end
  end
end