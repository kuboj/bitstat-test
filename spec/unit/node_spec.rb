require 'spec_helper'

describe Bitstat::Node do
  describe '#new' do
    it 'takes argument hash with two parameters: :id and :watchers_config' do
      expect { Bitstat::Node.new({}) }.to raise_error(IndexError)
      expect { Bitstat::Node.new(:id => nil, :watchers_config => {}) }.not_to raise_error
    end
  end

  let(:node) { Bitstat::Node.new(:id => nil, :watchers_config => {}) }

  describe '#get_watcher_class' do
    it 'returns watcher class by type' do
      node.get_watcher_class(:up).should eql Bitstat::Watchers::Up
      node.get_watcher_class(:average).should eql Bitstat::Watchers::Average
      node.get_watcher_class('average').should eql Bitstat::Watchers::Average
    end
  end

  describe '#create_watcher' do
    it 'creates new watcher according to type' do
      node.create_watcher(:diskinodes, :average, { :count => 10, :interval => 1 })
      node.watchers.should include(:diskinodes)
      node.watchers[:diskinodes].should include(:average)
      node.watchers[:diskinodes][:average].should be_a(Bitstat::Watchers::Average)
    end
  end

  describe '#delete_watcher' do
    before do
      node.create_watcher(:diskinodes, :average, { :count    => 10,
                                                   :interval => 1 })
      node.create_watcher(:diskinodes, :up, { :exceed_count => 10,
                                              :interval     => 1,
                                              :aging        => 0.1,
                                              :threshold    => 15 })
    end

    it 'deletes watcher according to type' do
      node.delete_watcher(:diskinodes, :average)
      node.watchers.should include(:diskinodes)
      node.watchers[:diskinodes].should_not include(:average)
    end

    it 'deletes whole watcher type section if empty' do
      node.delete_watcher(:diskinodes, :average)
      node.delete_watcher(:diskinodes, :up)
      node.watchers.should_not include(:diskinodes)
    end
  end

  describe '#create_watchers' do
    let(:config) { { :diskinodes => {
                         :up      => 'data',
                         :average => 'data2'
                      },
                      :cpubusy    => {
                         :average => 'data3'
                      } } }
    it 'calls #create_watcher with appropriate parameters for each watcher config' do
      node.should_receive(:create_watcher).once.with(:diskinodes, :up, 'data')
      node.should_receive(:create_watcher).once.with(:diskinodes, :average, 'data2')
      node.should_receive(:create_watcher).once.with(:cpubusy, :average, 'data3')
      node.create_watchers(config)
    end
  end

  describe '#delete_watchers' do
    let(:config) { { :diskinodes => {
                         :up      => 'data',
                         :average => 'data2'
                     },
                     :cpubusy    => {
                         :average => 'data3'
                     } } }
    it 'calls #delete_watcher with appropriate parameters for each watcher config' do
      node.should_receive(:delete_watcher).once.with(:diskinodes, :up)
      node.should_receive(:delete_watcher).once.with(:diskinodes, :average)
      node.should_receive(:delete_watcher).once.with(:cpubusy, :average)
      node.delete_watchers(config)
    end
  end

  describe '#update' do
    let(:watcher1) { double() }
    let(:watcher2) { double() }
    let(:watcher3) { double() }
    let(:data) { { :cpubusy => 23, :diskinodes => 2356235 } }
    before do
      node.instance_variable_set(:@watchers, {
          :cpubusy    => { :up => watcher1 },
          :diskinodes => { :down => watcher2 },
          :blah       => { :down => watcher3 },
      })
    end

    it 'calls #update with according data on each watcher' do
      watcher1.should_receive(:update).with(data[:cpubusy])
      watcher2.should_receive(:update).with(data[:diskinodes])
      node.update(data)
    end

    it 'will not call #update on watcher which data are not available' do
      watcher1.stub(:update)
      watcher2.stub(:update)
      watcher3.should_not_receive(:update)
      node.update(data)
    end
  end

  describe '#reload' do
    it 'calls #create_watchers and #delete_watchers with according parameters' do
      config = {
          :new     => 'new watchers',
          :deleted => 'deleted watchers'
      }
      node.should_receive(:create_watchers).with(config[:new])
      node.should_receive(:delete_watchers).with(config[:deleted])
      node.reload(config)
    end
  end
end
