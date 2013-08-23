require 'spec_helper'

describe Bitstat::DataProviders::ZfsDiskspace do
  describe '#new' do
    it 'takes options hash as parameter with one obligatory key: filesystem_prefix' do
      expect { Bitstat::DataProviders::ZfsDiskspace.new }.to raise_error(ArgumentError)
      expect { Bitstat::DataProviders::ZfsDiskspace.new({}) }.to raise_error(IndexError)
      expect { Bitstat::DataProviders::ZfsDiskspace.new({ :filesystem_prefix => nil }) }.not_to raise_error(IndexError)
    end
  end

  describe '#regenerate' do
    it 'calls zfs get command and parses each line of output' do
      zfs_text = <<-ZFS
          vz	34346945536
          vz/kubo	859500032
          vz/private	23183408128
          vz/private/200	901480960
          vz/private/201	827946496
          vz/private/202	955620352
          vz/private/203	979632640
          vz/private/204	979314176
          vz/private/205	931282432
          vz/private/206	827953152
          vz/private/207	979287552
          vz/private/208	842255360
          vz/private/209	842455552
          vz/private/210	1009346048
          vz/private/211	1009284096
          vz/private/212	830597632
          vz/private/213	830595072
          vz/private/214	828055040
          vz/private/215	852681216
          vz/private/216	837035008
          vz/private/217	966887424
          vz/private/218	964840448
          vz/private/219	875941376
          vz/private/220	842376192
          vz/private/221	845418496
          vz/private/224	847870464
          vz/private/225	854802944
          vz/private/226	847349248
          vz/template	10301658112
      ZFS

      zfs_diskspace = Bitstat::DataProviders::ZfsDiskspace.new({ :filesystem_prefix => 'vz/private/' })
      zfs_diskspace.stub(:get_zfs_get_output => zfs_text)
      zfs_diskspace.should_receive(:parse_line).exactly(zfs_text.lines.to_a.size).times
      zfs_diskspace.regenerate
    end
  end

  describe '#command' do
    it 'returns correct zfs get command' do
      zfs_diskspace = Bitstat::DataProviders::ZfsDiskspace.new({ :filesystem_prefix => 'vz/private/' })
      zfs_diskspace.command.should eql "zfs get -H -p used -t filesystem -o name,value"
    end
  end

  describe '#parse_line' do
    it 'parses zfs get output and returns hash with veid and megabytes' do
      zfs_diskspace = Bitstat::DataProviders::ZfsDiskspace.new({ :filesystem_prefix => 'vz/private/' })
      expected = {
          :veid      => 226,
          :diskspace => 808
      }
      zfs_diskspace.parse_line('           vz/private/226	847349248').should eql expected
    end

    it 'it returns nil if filesystem does not start with :filesystem_prefix' do
      zfs_diskspace = Bitstat::DataProviders::ZfsDiskspace.new({ :filesystem_prefix => 'vz/private/' })
      zfs_diskspace.parse_line('    vz/tralala   3525235235 ').should be_nil
    end
  end

  describe '#each_vps' do
    it 'calls block for each vps and passes vps to this block' do
      zfs_text = <<-ZFS
          vz/private/225	854802944
          vz/private/226	847349248
          vz/template	10301658112
      ZFS

      zfs_diskspace = Bitstat::DataProviders::ZfsDiskspace.new({ :filesystem_prefix => 'vz/private/' })
      zfs_diskspace.stub(:get_zfs_get_output => zfs_text)
      zfs_diskspace.regenerate
      expect { |b| zfs_diskspace.each_vps(&b) }.to yield_successive_args(
                                                { :veid => 225, :diskspace => 815 },
                                                { :veid => 226, :diskspace => 808 }
                                            )
    end
  end

  describe '#vpss' do
    it 'returns hash with ids as keys' do
      zfs_text = <<-ZFS
          vz	34346945536
          vz/kubo	859500032
          vz/private	23183408128
          vz/private/200	901480960
          vz/private/201	827946496
          vz/private/202	955620352
      ZFS

      zfs_diskspace = Bitstat::DataProviders::ZfsDiskspace.new({ :filesystem_prefix => 'vz/private/' })
      zfs_diskspace.stub(:get_zfs_get_output => zfs_text)
      zfs_diskspace.regenerate
      expected_hash = {
          200 => { :diskspace => 859 },
          201 => { :diskspace => 789 },
          202 => { :diskspace => 911 }
      }
      zfs_diskspace.vpss.should eql expected_hash
    end
  end
end
