require 'spec_helper'

describe Bitstat::Watchers::Average do
  before (:each) do
    @interval = 3
    @exceed_count    = 2
    @average  = Bitstat::Watchers::Average.new({
                                                   :interval     => @interval,
                                                   :exceed_count => @exceed_count
                                               })
  end

  describe '#new' do
    it 'takes hash with keys :interval and :exceed_count' do
      expect { Bitstat::Watchers::Average.new({}) }.to raise_error(IndexError)
      expect { Bitstat::Watchers::Average.new({
                                                  :interval     => nil,
                                                  :exceed_count => nil
                                              }) }.not_to raise_error
    end
  end

  describe '#notify?' do
    it 'returns true if #update was called more or equal than :exceed_count*:interval times' do
      @average.update(10)
      @average.notify?.should be_false
      @average.update(20) # ignored
      @average.notify?.should be_false
      @average.update(30) # ignored
      @average.notify?.should be_false
      @average.update(50)
      @average.notify?.should be_true
    end
  end

  describe '#reset' do
    it 'resets sum and average' do
      @average.update(10)
      @average.update(20) # ignored
      @average.update(30) # ignored
      @average.update(50)
      @average.reset
      @average.value.should eql 0.0
    end
  end

  describe '#value' do
    it 'returns average value passed to #update' do
      @average.update(10)
      @average.update(20) # ignored
      @average.update(30) # ignored
      @average.update(50)
      @average.value.should eql 30.0
    end

    it 'returns 0 if no values were provided' do
      @average.value.should eql 0.0
    end
  end
end