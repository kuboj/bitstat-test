require 'spec_helper'

describe Bitstat::DataProviders::Physpages do
  describe '#new' do
    it 'takes one parameter - resources path' do
      expect { Bitstat::DataProviders::Physpages.new({}) }.to raise_error(IndexError)
      expect { Bitstat::DataProviders::Physpages.new( :resources_path => nil ) }.not_to raise_error
    end
  end

  let(:physpages) { Bitstat::DataProviders::Physpages.new( :resources_path => "#{APP_DIR}/spec/unit/resources/resources") }

  describe '#regenerate' do
    it 'works' do
      expected = [{:veid=>1043, :physpages=>13747},
                  {:veid=>1041, :physpages=>83068},
                  {:veid=>1039, :physpages=>74940},
                  {:veid=>1037, :physpages=>279615},
                  {:veid=>1035, :physpages=>73303}]
      physpages.regenerate.should eql expected
    end
  end

  describe '#vpss' do
    before { physpages.regenerate }
    it 'returns hash of vpss indexed by id' do
      expected = {1039=>{:physpages=>74940},
                  1035=>{:physpages=>73303},
                  1041=>{:physpages=>83068},
                  1037=>{:physpages=>279615},
                  1043=>{:physpages=>13747}}
      physpages.vpss.should eql expected
    end
  end

  describe '#calculate_physpages' do
    it 'calculates number of 4KB physpages' do
      physpages.calculate_physpages(4796, 19172117, 33852).should eql 134946
    end
  end
end