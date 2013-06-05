require 'spec_helper'

describe Bitstat do
  $port = 12345

  describe 'control via http' do
    before do
      @controller = Bitstat::Controller.new(
          :port                => $port,
          :app_class           => Bitstat::SinatraApp,
          :application_options => nil
      )
      @sender = Bitstat::Sender.new(:url => "http://localhost:#$port")
      @application_stub = double()
      @application_stub.stub(:start)
      @application_stub.stub(:stop)
      @application_stub.stub(:reload)
      @controller.stub(:application).and_return(@application_stub)
      @controller.start
    end

    after do
      $port += 1
      @controller.stop
      sleep 0.5
    end

    it 'stops application' do
      @application_stub.should_receive(:reload).and_return( { :message => 'reloaded' } )
      @sender.send_data( :request => { :action => :reload }.to_json )
    end

    it 'requests node info' do
      node_id = 789
      @application_stub.should_receive(:node_info).with(node_id).and_return( { :message => 'das info' })
      @sender.send_data( :request => {:action => :node_info, :node_id => node_id}.to_json )
    end
  end
end