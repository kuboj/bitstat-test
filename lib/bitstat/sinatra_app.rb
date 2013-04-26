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
        puts "------- #{e.class}: #{e.message} -------"
        puts "------- #{e.backtrace[0]} -------"
        puts "------- #{e.backtrace[1]} -------"
        halt(500, "Error: #{e.class}: #{e.message}")
      end
    end
  end
end