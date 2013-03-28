require 'spec_helper'

describe Bitstat::Cpubusy do
  describe '#new' do
    it 'takes Vestat object as parameter' do
      expect { Bitstat::Cpubusy.new }.to raise_error(ArgumentError)
      expect { Bitstat::Cpubusy.new(Object.new) }.to raise_error(ArgumentError)
      expect { Bitstat::Cpubusy.new(Bitstat::Vestat.new({ :path => nil })) }.not_to raise_error
    end
  end

  describe '#regenerate!' do
    it 'calls #regenerate! on Vestat object' do
      vestat = Bitstat::Vestat.new({ :path => nil })
      vestat.should_receive(:regenerate!).once
      vestat.should_receive(:vpss).once
      cpubusy = Bitstat::Cpubusy.new(vestat)
      cpubusy.regenerate!
    end
  end

  describe '#calculate_diff' do
    before (:each) do
      @cpubusy = Bitstat::Cpubusy.new(Bitstat::Vestat.new({ :path => nil }))
    end
    it 'takes two hashes and returns hash' do
      expected_hash = {}
      @cpubusy.calculate_diff({}, {}).should eql expected_hash
    end

    it 'copies k-v pair from first hash if key not found in second hash' do
      h1 = {
          1 => {
              :a => 11,
              :b => 50,
              :c => 25
          },
          2 => {
              :a => 20,
              :b => 35,
              :c => 40
          },
      }
      h2 = {
          1 => {
              :a => 10,
              :b => 15,
              :c => 20
          }
      }
      h_expected = {
          1 => {
              :a => 1,
              :b => 35,
              :c => 5
          },
          2 => {
              :a => 20,
              :b => 35,
              :c => 40
          },
      }
      @cpubusy.calculate_diff(h1, h2).should eql h_expected
    end
  end

  describe '#each_vps' do
    before (:each) do
      @vestat = Bitstat::Vestat.new({ :path => nil })
      @vestat.stub(:regenerate!)
      @vestat.stub(:vpss).and_return(
          { 1 => { :idle => 10 }},
          { 1 => { :idle => 15 }, 2 => { :idle => 30}}
      )
      @cpubusy = Bitstat::Cpubusy.new(@vestat)
      @cpubusy.stub(:calculate_load)
    end

    it 'yields zero times if #regenerate! was not called' do
      expect { |b| @cpubusy.each_vps(&b) }.not_to yield_control
    end

    it 'yields zero times if #regenerate! was called only once' do
      @cpubusy.regenerate!
      expect { |b| @cpubusy.each_vps(&b) }.not_to yield_control
    end

    it 'passes to block hash with keys :cpubusy and :veid' do
      @cpubusy.stub(:calculate_load).and_return(1)
      @cpubusy.regenerate!
      @cpubusy.regenerate!
      expect { |b| @cpubusy.each_vps(&b) }.to yield_successive_args(
          { :veid => 1, :cpubusy => 1 },
          { :veid => 2, :cpubusy => 1 }
      )
    end
  end

  describe '#caluculate_load' do
    before (:each) do
      @vestat = Bitstat::Vestat.new({ :path => nil })
      @cpubusy = Bitstat::Cpubusy.new(@vestat)
    end

    it 'takes hash with keys :idle, :user, :nice and :system and calculates cpubusy time' do
      data = {
          :idle => 100000000,
          :user => 20,
          :nice => 30,
          :system => 50
      }
      @cpubusy.calculate_load(data).should eql 50.0

      data = {
          :idle => 300000000,
          :user => 20,
          :nice => 30,
          :system => 50
      }
      @cpubusy.calculate_load(data).should eql 25.0
    end

    it 'returns float' do
      data = {
          :idle => 100000000,
          :user => 20,
          :nice => 30,
          :system => 50
      }
      @cpubusy.calculate_load(data).should_not eql 50
      @cpubusy.calculate_load(data).should eql 50.0
    end
  end

  describe '#vpss' do
    before (:each) do
      @vestat = Bitstat::Vestat.new({ :path => nil })
      @vestat.stub(:regenerate!)
      @vestat.stub(:vpss).and_return(
          { 1 => {} },
          { 1 => {}, 2 => {} }
      )
      @cpubusy = Bitstat::Cpubusy.new(@vestat)
      @cpubusy.stub(:calculate_load)
    end

    it 'returns hash of vpss' do
      fake_cpubusy = 10.0
      @cpubusy.stub(:calculate_load).and_return(fake_cpubusy)
      @cpubusy.regenerate!
      @cpubusy.regenerate!
      expected = {
          1 => { :cpubusy => fake_cpubusy },
          2 => { :cpubusy => fake_cpubusy }
      }
      @cpubusy.vpss.should eql expected
    end
  end
end