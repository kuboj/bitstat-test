module Bitstat
  class Controller
    include Bitlogger::Loggable

    def initialize(options)
      @options             = options
      @port                = @options.fetch(:port)
      @app_class           = @options.fetch(:app_class)
      @application_options = @options.fetch(:application_options)
      # TODO: application.stop timeout ?
    end

    # NOTE: blocking call
    def start
      server.start
      application.start
    end

    def stop
      server.stop
      application.stop
      { :code => 0 }
    end

    def node_info(options)
      data = application.node_info(options.fetch(:node_id))
      { :code => 0, :data => data }
    end

    def reload
      application.reload
      { :code => 0 }
    end

    private
    def server
      @server ||= HttpServer.new(:app_class => @app_class,
                                 :port      => @port,
                                 :callback  => Proc.new { |params| on_request(params) })
    end

    def application
      @application ||= Application.new(@application_options)
    end

    def on_request(params)
      params = JSON.parse(params[:request])
      params = params.symbolize_string_keys
      action = params.delete(:action)
      if params.empty?
        (self.send(action.to_sym)).to_json
      else
        (self.send(action.to_sym, params)).to_json
      end
    rescue => e
      { :code => -1, :message => "#{e.class}: #{e.message}", :backtrace => e.backtrace }.to_json
    end
  end
end