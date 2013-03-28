require 'spec_helper'

describe Bitstat::DataProviders::Vzlist do
  describe '#new' do
    it 'takes array of fields as parameter' do
      expect { Bitstat::DataProviders::Vzlist.new }.to raise_error(ArgumentError)
      expect { Bitstat::DataProviders::Vzlist.new({}) }.to raise_error(IndexError)
      expect { Bitstat::DataProviders::Vzlist.new({ :fields => nil }) }.not_to raise_error(IndexError)
    end
  end

  describe '#regenerate!' do
    it 'calls vzlist command and parses each line of output' do
      vzlist_text = <<-VZLIST
       711      42851
       713      38662
       715      63114
       717      40695
       719      56508
       721      52436
      VZLIST

      vzlist = Bitstat::DataProviders::Vzlist.new({ :fields => %w(physpages) })
      vzlist.stub(:get_vzlist_output => vzlist_text)
      vzlist.should_receive(:parse_line).exactly(vzlist_text.lines.to_a.size).times
      vzlist.regenerate!
    end
  end

  describe '#command' do
    it 'returns correct vzlist command' do
      vzlist = Bitstat::DataProviders::Vzlist.new({ :fields => %w(physpages) })
      vzlist.command.should eql 'vzlist -Hto veid,physpages'
    end

    it 'always include "veid" field' do
      vzlist = Bitstat::DataProviders::Vzlist.new({ :fields => %w(cpulimit) })
      vzlist.command.should eql 'vzlist -Hto veid,cpulimit'
    end
  end

  describe '#parse_line' do
    it 'parses vzlist output and returns hash with symbolized keys passed in constructor' do
      vzlist = Bitstat::DataProviders::Vzlist.new({ :fields => %w(physpages hostname) })
      expected = {
          :veid      => '721',
          :physpages => '52435',
          :hostname  => 'crn721.c173.prg1.relbit.com'
      }
      vzlist.parse_line(' 721      52435 crn721.c173.prg1.relbit.com').should eql expected
    end

    it 'it returns nil for fields which cannot be parsed' do
      vzlist = Bitstat::DataProviders::Vzlist.new({ :fields => %w(physpages hostname) })
      expected = {
          :veid      => '721',
          :physpages => '52435',
          :hostname  => nil
      }
      vzlist.parse_line(' 721      52435   ').should eql expected
    end
  end

  describe '#each_vps' do
    it 'calls block for each vps and passes vps to this block' do
      vzlist_text = <<-VZLIST
       711      42851
       713      38662
       715      63114
      VZLIST

      vzlist = Bitstat::DataProviders::Vzlist.new({ :fields => %w(physpages) })
      vzlist.stub(:get_vzlist_output => vzlist_text)
      vzlist.regenerate!
      expect { |b| vzlist.each_vps(&b) }.to yield_successive_args(
          { :veid => '711', :physpages => '42851'},
          { :veid => '713', :physpages => '38662'},
          { :veid => '715', :physpages => '63114'}
      )
    end
  end

  describe '#vpss' do
    it 'returns hash with ids as keys' do
      vzlist_text = <<-VZLIST
       711      42851
       713      38662
       715      63114
      VZLIST

      vzlist = Bitstat::DataProviders::Vzlist.new({ :fields => %w(physpages) })
      vzlist.stub(:get_vzlist_output => vzlist_text)
      vzlist.regenerate!
      expected_hash = {
          711 => { :physpages => '42851' },
          713 => { :physpages => '38662' },
          715 => { :physpages => '63114' }
      }
      vzlist.vpss.should eql expected_hash
    end
  end
end
