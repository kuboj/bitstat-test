require 'spec_helper'

describe Bitstat do
  describe 'control via http' do
    before do
      @port = 10005
      @controller = Bitstat::Controller.new(:port => @port)
      @sender = Bitstat::Sender.new(:url => "http://localhost:#@port")
      @application_stub = double()
      @application_stub.stub(:start)
      @application_stub.stub(:stop)
      @controller.stub(:application).and_return(@application_stub)
      @controller.start
    end

    after { @controller.stop }

    #it 'works!' do
    #  action = 'testing_action'
    #  data   = { :a => 'b' }
    #  retval = { :b => 123 }
    #  @controller.should_receive(action.to_sym).with(data).and_return { retval }
    #  @sender.send_data((data).merge(:action => action)).should eql retval
    #end

    it 'stops application' do
      @application_stub.should_receive(:reload).and_return('reloaded')
      require 'pp'
      pp @sender.send_data({ :action => :reload })
    end

    it 'requests node info' do
      node_id = 789
      @application_stub.should_receive(:node_info).with(node_id).and_return('das info')
      pp @sender.send_data( {:action => :node_info, :node_id => node_id}.to_json )
    end
  end
end