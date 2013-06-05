require 'spec_helper'

describe Bitstat::Collector do
  before (:each) do
    @collector = Bitstat::Collector.new
  end

  describe '#set_data_provider' do
    it 'adds data provider at given key if already does not exist' do
      provider = double()
      provider.should_receive(:regenerate).once
      @collector.set_data_provider(:test, provider)
      @collector.regenerate
    end

    it 'replaces existing data provider at given key if present' do
      provider1 = double()
      provider1.should_not_receive(:regenerate)
      provider2 = double()
      provider2.should_receive(:regenerate)
      @collector.set_data_provider(:test, provider1)
      @collector.set_data_provider(:test, provider2)
      @collector.regenerate
    end
  end

  describe '#delete_data_provider' do
    it 'deletes data provider with given key therefore it would get no more #regenerate calls' do
      provider = double()
      provider.should_not_receive(:regenerate)
      @collector.set_data_provider(:test, provider)
      @collector.delete_data_provider(:test)
      @collector.regenerate
    end

    it 'returns nil if data provider with given key does not exist' do
      @collector.delete_data_provider(:test).should be_nil
    end
  end

  describe '#regenerate' do
    it 'calls #regenerate on each data_provider' do
      provider1 = double()
      provider1.should_receive(:regenerate)
      provider2 = double()
      provider2.should_receive(:regenerate)
      @collector.set_data_provider(:cpubusy, provider1)
      @collector.set_data_provider(:diskinodes, provider2)
      @collector.regenerate
    end


    it 'would not call #regenerate on replaced data_provider' do
      provider1 = double()
      provider1.should_not_receive(:regenerate)
      provider2 = double()
      provider2.should_receive(:regenerate)
      @collector.set_data_provider(:cpubusy, provider1)
      @collector.set_data_provider(:cpubusy, provider2)
      @collector.regenerate
    end
  end

  describe '#get_data' do
    it 'calls #vpss on each data_provider and merges those hashes via veid' do
      provider1 = double()
      provider1.stub(:vpss).and_return({ 1 => { :cpubusy => 10 } })
      provider2 = double()
      provider2.stub(:vpss).and_return({ 1 => { :diskinodes => 100 }, 2 => { :diskinodes => 200 } })
      @collector.set_data_provider(:cpubusy, provider1)
      @collector.set_data_provider(:diskinodes, provider2)
      expected = {
          1 => { :diskinodes => 100, :cpubusy => 10 },
          2 => { :diskinodes => 200 }
      }
      @collector.get_data.should eql expected
    end
  end

  describe '#notify_all' do
    it 'calls #update on all observers with new data' do
      mocked_data = { 1 => { :cpubusy => 10 } }
      @collector.stub(:get_data).and_return(mocked_data)
      observer1 = double()
      observer2 = double()
      observer1.should_receive(:update).with(mocked_data)
      observer2.should_receive(:update).with(mocked_data)
      @collector.set_observer(10, observer1)
      @collector.set_observer(20, observer2)
      @collector.regenerate
      @collector.notify_all
    end

    it 'would not notify deleted observers' do
      mocked_data = { 1 => { :cpubusy => 10 } }
      @collector.stub(:get_data).and_return(mocked_data)
      observer1 = double()
      observer2 = double()
      observer1.should_not_receive(:update)
      observer2.should_receive(:update).with(mocked_data)
      @collector.set_observer(10, observer1)
      @collector.delete_observer(10)
      @collector.set_observer(20, observer2)
      @collector.regenerate
      @collector.notify_all
    end
  end

  describe '#set_observer' do
    it 'adds new observer' do
      observer = double()
      observer.should_receive(:update).once
      @collector.set_observer(2, observer)
      @collector.notify_observers({})
    end

    it 'replaces observer if observer with same id already exists' do
      observer1 = double()
      observer1.should_not_receive(:update)
      observer2 = double()
      observer2.should_receive(:update).once
      @collector.set_observer(1, observer1)
      @collector.set_observer(1, observer2)
      @collector.notify_observers({})
    end
  end

  describe '#delete_observer' do
    it 'deletes observer therefore it would get #update no more' do
      observer = double()
      observer.should_not_receive(:update)
      @collector.set_observer(1, observer)
      @collector.delete_observer(1)
      @collector.notify_observers({})
    end

    it 'returns nil if observer with given id does not exist' do
      @collector.delete_observer(:test).should be_nil
    end
  end

  describe '#notify_observers' do
    it 'calls #update on each observer with given data' do
      mocked_data = { 1 => { :cpubusy => 10 }, 2 => { :physpages => 234 } }
      observer1 = double()
      observer1.should_receive(:update).once.with(mocked_data)
      observer2 = double()
      observer2.should_receive(:update).once.with(mocked_data)
      @collector.set_observer(1, observer1)
      @collector.set_observer(2, observer2)
      @collector.notify_observers(mocked_data)
    end
  end
end