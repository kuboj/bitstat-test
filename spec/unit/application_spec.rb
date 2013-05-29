require 'spec_helper'

describe Bitstat::Application do
  let(:valid_args) {
    {
        :vestat_path       => nil,
        :vzlist_fields     => nil,
        :nodes_config_path => nil,
        :ticker_interval   => nil
    }
  }

  describe '#new' do
    it 'takes 4 parameters' do
      expect { Bitstat::Application.new({}) }.to raise_error(IndexError)
      expect { Bitstat::Application.new(valid_args) }.not_to raise_error
    end
  end

  let(:application) {
    Bitstat::Application.new({
                                 :vestat_path       => nil,
                                 :vzlist_fields     => nil,
                                 :nodes_config_path => nil,
                                 :ticker_interval   => nil
                             })
  }
  let(:collector)        { double() }
  let(:vzlist)           { double() }
  let(:cpubusy)          { double() }
  let(:ticker)           { double() }
  let(:collector_thread) { double() }
  let(:nodes_config)     { double() }
  let(:nodes)            { double() }

  before do
    application.stub(:collector).and_return(collector)
    application.stub(:vzlist).and_return(vzlist)
    application.stub(:cpubusy).and_return(cpubusy)
    application.stub(:ticker).and_return(ticker)
    application.stub(:collector_thread).and_return(collector_thread)
    application.stub(:nodes_config).and_return(nodes_config)
    application.stub(:nodes).and_return(nodes)
    collector_thread.stub(:signal)
    collector.stub(:set_data_provider)
    collector.stub(:set_observer)
    collector.stub(:delete_observer)
    ticker.stub(:start)
    ticker.stub(:stop)
  end

  describe '#start' do
    it 'sets data providers to collector and starts ticker' do
      collector.should_receive(:set_data_provider).with(:vzlist, vzlist)
      collector.should_receive(:set_data_provider).with(:cpubusy, cpubusy)
      ticker.should_receive(:start)
      application.start
    end
  end

  describe '#stop' do
    before { application.start }
    it 'stops ticker' do
      ticker.should_receive(:stop)
      application.stop
    end
  end

  describe '#reload' do
    let(:config) {
      {
          :new => {
              1 => 'config1',
              2 => 'config2',
              3 => 'config3'
          },
          :modified => {
              6 => 'blah'
          },
          :deleted => {
              4 => 'config4',
              5 => 'config5',
          }
      }
    }

    let(:node) { double() }

    before do
      nodes_config.stub(:reload).and_return(config)
      node.stub(:reload)
      nodes.stub(:[]).and_return(node)
    end

    it 'creates new nodes' do
      application.stub(:delete_node)
      config[:new].each do |id, c|
        application.should_receive(:create_node).with(id, c)
        collector.should_receive(:set_observer)
      end
      application.reload
    end

    it 'deletes nodes' do
      application.stub(:create_node)
      config[:deleted].each do |id, c|
        application.should_receive(:delete_node).with(id)
        collector.should_receive(:delete_observer).with(id)
      end
      application.reload
    end

    it 'reloads modified nodes' do
      application.stub(:create_node)
      application.stub(:delete_node)
      node.should_receive(:reload).with('blah')
      application.reload
    end
  end
end
