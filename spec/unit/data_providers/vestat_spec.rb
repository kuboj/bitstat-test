require 'spec_helper'

describe Bitstat::DataProviders::Vestat do
  describe '#new' do
    it 'takes hash with as parameter with obligatory key `path`' do
      expect { Bitstat::DataProviders::Vestat.new }.to raise_error(ArgumentError)
      expect { Bitstat::DataProviders::Vestat.new({}) }.to raise_error(IndexError)
      expect { Bitstat::DataProviders::Vestat.new({ :path => '/proc/vz/vestat' }) }.not_to raise_error
    end
  end

  describe '#regenerate' do
    it 'reads file and parses each line' do
      vestat_text = <<-VESTAT
Version: 2.2
                VEID                 user                 nice               system               uptime                 idle                 strv               uptime                 used               maxlat               totlat             numsched
                 721                66017                   17               139850            104123408      101385808831824                    0      104123409048607         271334829526                    0                    0                    0
                 719               779973                   13               457112            104352274      106365771148640                    0      104352274720395        1309046705295                    0                    0                    0
                 717               117552                   15               292414            104577038      101321395698055                    0      104577038844598         481582384839                    0                    0                    0
      VESTAT

      vestat = Bitstat::DataProviders::Vestat.new({ :path => nil })
      vestat.stub(:get_vestat_output => vestat_text)
      vestat.should_receive(:parse_line).exactly(3).times
      vestat.regenerate
    end
  end

  describe '#skip_line?' do
    it 'returns true if line includes headers' do
      vestat = Bitstat::DataProviders::Vestat.new({ :path => nil })
      vestat.skip_line?(' kvik').should be_false
      vestat.skip_line?('blabla Version bla').should be_true
      vestat.skip_line?('     Version').should be_true
      vestat.skip_line?(' VEID ').should be_true
    end
  end

  describe '#parse_line' do
    it 'returns array of integers with 1st, 2nd, 3rd, 4th and 6th column' do
      vestat = Bitstat::DataProviders::Vestat.new({ :path => nil })
      vestat.parse_line('   1    2   3   4   5      6   7  8 9').should eql [1, 2, 3, 4, 6]
      vestat.parse_line('1    2   3  4 5 6').should eql [1, 2, 3, 4, 6]
    end

    it 'returns nil when values are not available' do
      vestat = Bitstat::DataProviders::Vestat.new({ :path => nil })
      vestat.parse_line('  1 2').should eql [1, 2, nil, nil, nil]
    end
  end

  describe '#get_vestat_output' do
    it 'calls readlines on file given in constructor' do
      vestat = Bitstat::DataProviders::Vestat.new({ :path => 'path' })
      File.should_receive(:readlines).with('path')
      vestat.get_vestat_output
    end
  end

  describe '#each_vps' do
    it 'calls block for each vps and passes vps to this block' do
      vestat_text = <<-VESTAT
Version: 2.2
                VEID                 user                 nice               system               uptime                 idle                 strv               uptime                 used               maxlat               totlat             numsched
                 721                66017                   17               139850            104123408      101385808831824                    0      104123409048607         271334829526                    0                    0                    0
                 719               779973                   13               457112            104352274      106365771148640                    0      104352274720395        1309046705295                    0                    0                    0
                 717               117552                   15               292414            104577038      101321395698055                    0      104577038844598         481582384839                    0                    0                    0
      VESTAT

      vestat = Bitstat::DataProviders::Vestat.new({ :path => nil })
      vestat.stub(:get_vestat_output => vestat_text)
      vestat.regenerate
      expect { |b| vestat.each_vps(&b) }.to yield_successive_args(
          { :veid => 721, :user => 66017, :nice => 17, :system => 139850, :idle => 101385808831824 },
          { :veid => 719, :user => 779973, :nice => 13, :system => 457112, :idle => 106365771148640 },
          { :veid => 717, :user => 117552, :nice => 15, :system => 292414, :idle => 101321395698055 }
      )
    end
  end

  describe '#vpss' do
    it 'returns hash with ids as keys' do
      vestat_text = <<-VESTAT
Version: 2.2
                VEID                 user                 nice               system               uptime                 idle                 strv               uptime                 used               maxlat               totlat             numsched
                 721                66017                   17               139850            104123408      101385808831824                    0      104123409048607         271334829526                    0                    0                    0
                 719               779973                   13               457112            104352274      106365771148640                    0      104352274720395        1309046705295                    0                    0                    0
                 717               117552                   15               292414            104577038      101321395698055                    0      104577038844598         481582384839                    0                    0                    0
      VESTAT

      vestat = Bitstat::DataProviders::Vestat.new({ :path => nil })
      vestat.stub(:get_vestat_output => vestat_text)
      vestat.regenerate
      expected_hash = {
          721 => { :user => 66017, :nice => 17, :system => 139850, :idle => 101385808831824 },
          719 => { :user => 779973, :nice => 13, :system => 457112, :idle => 106365771148640 },
          717 => { :user => 117552, :nice => 15, :system => 292414, :idle => 101321395698055 }
      }
      vestat.vpss.should eql expected_hash
    end
  end
end