module Bitstat
  class NotifyQueue
    include Bitlogger::Loggable
    extend Forwardable
    def_delegators :@queue, :<<, :push

    NOTIFY_ACTION = 'bitstat'

    def initialize(options)
      @sender  = options.fetch(:sender)
      @node_id = options.fetch(:node_id)
      @queue   = Queue.new
    end

    def flush
      to_send = []
      @queue.size.times { to_send << format_notification(@queue.pop) }
      send_notifications(to_send) unless to_send.empty?
    end

    def send_notifications(notifications)
      @sender.send_data(format_data(notifications))
    end

    def format_notification(notification)
      [
          notification[:node_id],
          notification[:parameter],
          notification[:watcher_type],
          notification[:value]
      ]
    end

    def format_data(notifications)
      {
          :notify => {
              :action => NOTIFY_ACTION,
              :data   => {
                  :node_id       => @node_id,
                  :notifications => notifications
              }
          }.to_json
      }
    end
  end
end
