module Bitstat
  class Sender
    include Bitlogger::Loggable

    def initialize(options)
      @url         = options.fetch(:url)
      @verify_ssl  = options.fetch(:verify_ssl,  false)
      @crt_path    = options.fetch(:crt_path,    nil)
      @max_retries = options.fetch(:max_retries, 3)
      @wait_time   = options.fetch(:wait_time,   1)
    end

    def send_data(data)
      response = nil
      success = try(:count  => @max_retries,
                    :wait   => @wait_time,
                    :rescue => [RestClient::InternalServerError, Errno::ECONNREFUSED]) do
        response = rc_send(data)
        response.code == 200
      end
      parse_response(response)
    rescue => e
      error("Error sending request (#{data.to_json} to #@url}", e)
      nil
    end

    def ssl?
      !!@crt_path
    end

    def rc_send(data)
      RestClient::Request.execute(get_request(data))
    end

    def parse_response(response)
      return response if response.nil?
      JSON.parse(response).symbolize_string_keys
    rescue => e
      error("Error while parsing json #{e.class.name}:#{e.message}", e)
      nil
    end

    def get_request(data)
      request = {
          :method  => :post,
          :url     => @url,
          :payload => data
      }

      if ssl?
        request[:ssl_ca_file] = @crt_path
        request[:verify_ssl]  = @verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      end

      request
    end

    def try(options, &block)
      count      = options.fetch(:count, 3)
      exceptions = options.fetch(:rescue, [])
      wait_time  = options.fetch(:wait, 1)
      retries = 0
      success = false
      if exceptions.empty?
        while retries < count && !success
          retries += 1
          r = block.call(retries)
          success = r
          sleep(wait_time) unless success
        end
      else
        while retries < count && !success
          retries += 1
          r = false
          begin
            r = block.call(retries)
          rescue *exceptions => e
            error("Error in #{e.backtrace[1]}", e)
          end
          success = r
          sleep(wait_time) unless success
        end
      end

      success
    end
  end
end