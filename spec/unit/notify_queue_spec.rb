require 'spec_helper'

describe Bitstat::NotifyQueue do
  describe '#new' do

  end

  let(:sender)       { double() }
  let(:node_id)      { 1 }
  let(:notify_queue) { Bitstat::NotifyQueue.new(:sender => sender, :node_id => node_id) }
  let(:n1)           { {
                           :node_id      => 10,
                           :parameter    => :cpubusy,
                           :watcher_type => :up,
                           :value        => 99
                      } }
  let(:n2)            { {
                           :node_id      => 11,
                           :parameter    => :physpages,
                           :watcher_type => :average,
                           :value        => 539
                      } }

  before { sender.stub(:send_data) }

  describe 'method delegating' do
    it 'delegates :<< to queue' do
      notify_queue.instance_variable_get(:@queue).should_receive(:<<).with(n1)
      notify_queue << n1
    end

    it 'delegates :push to queue' do
      notify_queue.instance_variable_get(:@queue).should_receive(:push).with(n2)
      notify_queue.push(n2)
    end
  end

  describe '#format_notification' do
    it 'turns notification hash into array' do
      notify_queue.format_notification(n1).should eql [10, :cpubusy, :up, 99]
    end
  end

  describe '#flush' do
    before { notify_queue << n1 << n2 }

    it 'formats notifications' do
      notify_queue.should_receive(:format_notification).once.with(n1).and_call_original
      notify_queue.should_receive(:format_notification).once.with(n2).and_call_original
      notify_queue.should_receive(:format_data).once.with([[10, :cpubusy, :up, 99],
                                                           [11, :physpages, :average, 539]])
      notify_queue.flush
    end

    it 'sends formatted notifications to sender' do
      data = 'data'
      notify_queue.stub(:format_notification)
      notify_queue.should_receive(:format_data).and_return(data)
      sender.should_receive(:send_data).with(data)
      notify_queue.flush
    end
  end
end
