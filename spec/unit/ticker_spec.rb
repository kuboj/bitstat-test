require 'spec_helper'

describe Bitstat::Ticker do
  describe '#new' do
    it 'takes only one argument - interval' do
      expect { Bitstat::Ticker.new() }.to raise_error(ArgumentError)
      expect { Bitstat::Ticker.new(10) }.not_to raise_error
    end
  end

  let(:interval) { 0.1 }
  let(:ticker) { Bitstat::Ticker.new(interval) }

  describe '#start' do
    it 'takes block as argument' do
      expect { ticker.start(10) }.to raise_error(ArgumentError)
      expect { ticker.start {} }.not_to raise_error
    end

    it 'calls given block each `interval` seconds' do
      t = []
      ticker.start { t << (Time.now.to_f * 10).to_i }
      sleep 0.8
      (t[1] - t[0]).should eql 1
      (t[2] - t[1]).should eql 1
      (t[3] - t[2]).should eql 1
    end
  end

  describe '#stop' do
    let(:m) { Mutex.new }

    it 'prevents from next execution of block given in #start' do
      i = 0
      ticker.start do
        sleep 0.3
        m.synchronize { i = 1 }
      end
      ticker.stop
      ticker.join
      m.synchronize { i }.should eql 1
    end
  end

  describe '#stop!' do
    let(:m) { Mutex.new }

    it 'kills inner ticker thread' do
      i = 0
      ticker.start do
        sleep 1
        m.synchronize { i = 1 }
      end
      ticker.stop!
      ticker.join
      m.synchronize { i }.should eql 0
    end
  end
end