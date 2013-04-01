require 'spec_helper'

describe Bitstat::Watchers::Average do
  describe '#new' do
    it 'takes hash with keys :threshold, :exceed_count, :interval and :aging' do
      expect { Bitstat::Watchers::Average.new({}) }.to raise_error(IndexError)
      expect { Bitstat::Watchers::Average.new({
                                                  :interval => nil,
                                                  :count    => nil
                                              }) }.not_to raise_error
    end
  end

  describe '#notify?' do
    it 'returns true if #update was called more or equal than :count times'
  end

  describe '#reset' do
    it 'resets sum and average'
  end

  describe '#update' do
    it 'increases value_counter and sum'
    it 'returns false and does nothing if called less than :interval times'
    it 'returns true if called :interval times'
    it 'returns true if called more than :interval times'
  end

  describe '#value' do
    it 'returns average value passed to #update'
  end
end