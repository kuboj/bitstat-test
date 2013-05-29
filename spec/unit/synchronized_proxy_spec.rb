require 'spec_helper'
Thread.abort_on_exception = true

describe Bitstat::SynchronizedProxy do
  describe '#new' do
    it 'takes object to wrap in constructor' do
      expect { Bitstat::SynchronizedProxy.new() }.to raise_error(ArgumentError)
      expect { Bitstat::SynchronizedProxy.new(double()) }.not_to raise_error
    end
  end

  describe 'method call forwarding' do
    it 'calls method of provided object' do
      o = double()
      a = ['some', 'arguments', 3]
      p = Bitstat::SynchronizedProxy.new(o)
      o.should_receive(:some_method).with(*a)
      p.some_method(*a)
    end

    it 'provides synchronized access to underlying object' do
      q = Queue.new
      p = Bitstat::SynchronizedProxy.new(q)
      t1 = Thread.new { p.pop() }
      t2 = Thread.new { p.pop() }
      sleep 0.5
      q.num_waiting.should eql 1
    end
  end
end