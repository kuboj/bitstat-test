require 'spec_helper'

describe Bitstat::Watchers::Up do
  before (:each) do
    @threshold    = 80
    @exceed_count = 2
    @interval     = 3
    @aging        = 0.1
    @up = Bitstat::Watchers::Up.new({
                                        :threshold    => @threshold,
                                        :exceed_count => @exceed_count,
                                        :interval     => @interval,
                                        :aging        => @aging
                                    })
  end

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
    it 'returns true if threshold had been hit exactly exceed_count times' do
      @up.update(80)
      @up.notify?.should be_false
      @up.update(20) # ignored
      @up.notify?.should be_false
      @up.update(30) # ignored
      @up.notify?.should be_false
      @up.update(90)
      @up.notify?.should be_true
    end

    it 'returns true if threshold had been hit more than exceed_count times' do
      @up.update(80)
      @up.notify?.should be_false
      @up.update(20) # ignored
      @up.notify?.should be_false
      @up.update(30) # ignored
      @up.notify?.should be_false
      @up.update(90)
      @up.update(100) # ignored
      @up.update(100) # ignored
      @up.update(100)
      @up.notify?.should be_true
    end
  end

  describe '#age' do
    it 'subtracts aging parameter from count' do
      @up.update(90)
      @up.update(100) # ignored
      @up.update(100) # ignored
      @up.update(90)
      @up.notify?.should be_true
      @up.age
      @up.notify?.should be_false
    end
  end

  describe '#reset' do
    it 'resets threshold hit counter' do
      @up.update(90)
      @up.update(100) # ignored
      @up.update(100) # ignored
      @up.update(90)
      @up.notify?.should be_true
      @up.reset
      @up.notify?.should be_false
    end
  end

  describe '#value' do
    it 'returns last value passed to #update when it returned true' do
      @up.update(353)
      @up.value.should eql 353
    end
  end
end