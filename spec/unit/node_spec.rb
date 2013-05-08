require 'spec_helper'

describe Bitstat::Node do
  describe '#new' do
    it 'takes argument hash with one parameter. :id' do
      expect { Bitstat::Node.new({}) }.to raise_error(IndexError)
      expect { Bitstat::Node.new(:id => nil) }.not_to raise_error
    end
  end

  describe '#watcher_config_diff' do
    describe ''
  end
end
