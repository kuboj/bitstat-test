module Bitstat
  class Sender
    include Bitlogger::Loggable

    def initialize(options)
      @port = options.fetch(:port)
      @host = options.fetch(:host)
    end

    def send(data)
      JSON.parse(rc_send(url, data)).symbolize_string_keys
    rescue => e
      error("Error sending request (#{data.to_json} to #{url}}", e)
      nil
    end

    def url
      "http://#@host:#@port"
    end

    private
    def rc_send(url, data)
      RestClient.post(url, data)
    end
  end
end