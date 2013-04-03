require 'spec_helper'

describe Bitstat::CallFilter do
  before (:each) do
    class A
      extend Bitstat::CallFilter
      def initialize; @interval = 3 end
      def a; 1 end
      call_only_each(:a, :@interval)
    end
  end

  describe '.call_only_each' do
    it 'calls original method only when called multiply of :interval times' do
      a = A.new
      a.a.should eql 1
      a.a.should be_false
      a.a.should be_false
      a.a.should eql 1
      a.a.should be_false
      a.a.should be_false
      a.a.should eql 1
    end
  end

  describe '.change_call_interval' do
    it 'changes call interval' do
      a = A.new
      a.a.should eql 1
      a.a.should be_false
      a.a.should be_false
      a.a.should eql 1
      a.a.should be_false
      a.a.should be_false
      a.a.should eql 1
      a.interval = 5
      a.a.should be_false
      a.a.should be_false
      a.a.should be_false
      a.a.should be_false
      a.a.should eql 1
      a.a.should be_false
      a.a.should be_false
      a.a.should be_false
      a.a.should be_false
      a.a.should eql 1
    end
  end
end
