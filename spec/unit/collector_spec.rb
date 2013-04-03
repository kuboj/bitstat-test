require 'spec_helper'

describe Bitstat::Collector do
  before (:each) do
    @collector = Bitstat::Collector.new
  end

  describe '#set_data_provider' do
    it 'adds data provider at given key if already does not exist'
    it 'replaces existing data provider at given key if present'
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
      @collector.add_observer(observer1)
      @collector.add_observer(observer2)
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
      @collector.add_observer(observer1)
      @collector.delete_observer(observer1)
      @collector.add_observer(observer2)
      @collector.regenerate
      @collector.notify_all
    end
  end
end