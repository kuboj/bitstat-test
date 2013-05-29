module Bitstat
  class SynchronizedProxy
    include MonitorMixin

    def initialize(object)
      @object = object
      super()
    end

    def method_missing(meth, *args, &block)
      if @object.respond_to?(meth)
        self.synchronize { @object.send(meth, *args, &block) }
      else
        super
      end
    end
  end
end