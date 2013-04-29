module Bitstat
  class SinatraApp < Sinatra::Base
    include Bitlogger::Loggable

    def self.set_callback(callback)
      @@callback = callback
    end

    post '/' do
      begin
        [200, @@callback.call(params)]
      rescue => e
        halt(500, "Error: #{e.class}: #{e.message}")
      end
    end
  end
end