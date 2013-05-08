require 'spec_helper'

describe Bitstat::NodesConfig do
  describe '#new' do
    it 'takes one key as parameter - :path' do
      expect { Bitstat::NodesConfig.new({}) }.to raise_error(IndexError)
      expect { Bitstat::NodesConfig.new(:path => nil) }.not_to raise_error
    end
  end

  before do
    @nodes_config = Bitstat::NodesConfig.new(:path => nil)
  end

  describe '#diff' do
    describe 'when given empty hash as second parameter' do
      it 'returns first parameter and two empty hashes' do
        h1 = { :a => 10, :b => { :c => 44 } }
        h2 = {}
        @nodes_config.diff(h1, h2).should eql [h1, {}, {}]
      end
    end

    describe 'when given two hashes with different keys' do
      it 'returns first one, empty hash and second one' do
        h1 = { :a => 10, :b => { :c => 44 } }
        h2 = { :g => 4 }
        @nodes_config.diff(h1, h2).should eql [h1, {}, h2]
      end
    end

    describe 'when given two hashes with overlapping keys' do
      it 'returns hash with new keys, hash with modified keys and hash with keys only in second hash' do
        h1 = { :new => 10, :modified => { :c => 44 } }
        h2 = { :modified => 4, :deleted => 13 }

        @nodes_config.diff(h1, h2).should eql [
                                                  { :new => 10 },
                                                  { :modified => { :c => 44 } },
                                                  { :deleted => 13 }
                                              ]
      end
    end
  end
end
