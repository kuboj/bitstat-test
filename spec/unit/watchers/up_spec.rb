require 'spec_helper'

describe Bitstat::Watchers::Up do
  describe '#new' do
    it 'takes hash with keys :threshold, :exceed_count, :interval and :aging' do
      expect { Bitstat::Watchers::Up.new({}) }.to raise_error(IndexError)
      expect { Bitstat::Watchers::Up.new({
                                             :threshold    => nil,
                                             :exceed_count => nil,
                                             :interval     => nil
                                         }) }.to raise_error(IndexError)
      expect { Bitstat::Watchers::Up.new({
                                             :threshold    => nil,
                                             :exceed_count => nil,
                                             :interval     => nil,
                                             :aging        => nil
                                         }) }.not_to raise_error
    end
  end

  describe '#notify?' do
    it 'returns true if threshold had been hit exactly exceed_count times'
    it 'returns true if threshold had been hit more than exceed_count times'
    it 'returns false if threshold has not been hit at least exceed_count times'
  end

  describe '#age' do
    it 'subtracts aging parameter from count'
  end

  describe '#reset' do
    it 'resets threshold hit counter'
  end

  describe '#update' do
    it 'sets :last_value and'
    it 'returns false and does nothing if called less than :interval times'
    it 'returns true if called :interval times'
    it 'returns true if called more than :interval times'
    it 'increases @count if new value hits :threshold'
  end

  describe '#value' do
    it 'returns last value passed to #update when it returned true'
  end
end