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
      expected = [{:veid=>1043, :physpages=>13},
                  {:veid=>1041, :physpages=>81},
                  {:veid=>1039, :physpages=>73},
                  {:veid=>1037, :physpages=>273},
                  {:veid=>1035, :physpages=>71}]
      physpages.regenerate.should eql expected
    end
  end

  describe '#vpss' do
    before { physpages.regenerate }
    it 'returns hash of vpss indexed by id' do
      expected = {1039=>{:physpages=>73},
                  1035=>{:physpages=>71},
                  1041=>{:physpages=>81},
                  1037=>{:physpages=>273},
                  1043=>{:physpages=>13}}
      physpages.vpss.should eql expected
    end
  end

  describe '#calculate_mb' do
    it 'calculates megabytes' do
      physpages.calculate_mb(4796, 19172117, 33852).should eql 131
    end
  end
end