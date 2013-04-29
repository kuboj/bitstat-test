require 'spec_helper'

describe Bitstat do
  describe '' do
    before do
      @port = 10000
      @controller = Bitstat::Controller.new(:port => @port)
      @sender = Bitstat::Sender.new(:port => @port, :host => 'localhost')
      @application_stub = double()
      @application_stub.stub(:start)
      @controller.stub(:application).and_return(@application_stub)
      @controller.start
    end

    it 'works!' do
      action = 'testing_action'
      data   = { :a => 'b' }
      retval = { :b => 123 }
      @controller.should_receive(action.to_sym).with(data).and_return { retval }
      @sender.send((data).merge(:action => action)).should eql retval
    end
  end
end