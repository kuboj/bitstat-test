require 'spec_helper'

describe Bitstat::NodesConfig do
  describe '#new' do
    it 'takes one key as parameter - :path' do
      expect { Bitstat::NodesConfig.new({}) }.to raise_error(IndexError)
      expect { Bitstat::NodesConfig.new(:path => nil) }.not_to raise_error
    end
  end

  let(:nodes_config) { Bitstat::NodesConfig.new(:path => nil) }

  describe '#watchers_diff' do
    it 'returns hash with diff' do
      new_config = {
          :diskinodes => {
              :up   => 'something',
              :down => 'blah'
          },
          :cpubusy => {
              :average => 'blahblah'
          },
          :physpages => {
              :up      => 'hm',
              :down    => 'hm'
          }
      }
      old_config = {
          :cpubusy => {
              :up      => 'blah',
              :down    => 'blahblah',
              :average => 'will change'
          },
          :physpages => {
              :average => 'meh',
              :up      => 'hm',
              :down    => 'hm'
          }
      }
      expected = {
          :new => {
              :diskinodes => {
                  :up   => 'something',
                  :down => 'blah'
              },
              :cpubusy => {
                  :average => 'blahblah'
              }
          },
          :deleted => {
              :physpages => {
                  :average => 'meh'
              },
              :cpubusy => {
                  :up      => 'blah',
                  :down    => 'blahblah',
                  :average => 'will change'
              }
          }
      }

      nodes_config.watchers_diff(new_config, old_config).should eql expected
    end
  end

  describe '#diff' do
    it 'returns diff' do
      new_config = {
          1 => {
              :diskinodes => {
                  :up   => 'something',
                  :down => 'blah'
              }
          },
          2 => {
              :diskinodes => {
                  :up   => 'something',
                  :down => 'blah'
              },
              :cpubusy => {
                  :average => 'blahblah'
              },
              :physpages => {
                  :up      => 'hm',
                  :down    => 'hm'
              }
          }
      }
      old_config = {
          2 => {
              :diskspace => {
                  :average => 'mnaf'
              },
              :cpubusy => {
                  :average => 'blahblah'
              },
              :physpages => {
                  :up      => 'hmhm',
                  :down    => 'hmhm'
              }
          },
          3 => {
              :diskinodes => {
                  :up => 'blah'
              }
          }
      }
      expected = {
          :new => {
              1 => {
                  :diskinodes => {
                      :up   => 'something',
                      :down => 'blah'
                  }
              }
          },
          :modified => {
              2 => {
                  :new => {
                      :physpages => {
                          :up      => 'hm',
                          :down    => 'hm'
                      },
                      :diskinodes => {
                          :up   => 'something',
                          :down => 'blah'
                      }
                  },
                  :deleted => {
                      :diskspace => {
                          :average => 'mnaf'
                      },
                      :physpages => {
                          :up      => 'hmhm',
                          :down    => 'hmhm'
                      }
                  }
              }
          },
          :deleted => {
              3 => {
                  :diskinodes => {
                      :up => 'blah'
                  }
              }
          }
      }

      nodes_config.diff(new_config, old_config).should eql expected
    end
  end
end
