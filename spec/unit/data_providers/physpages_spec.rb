require 'spec_helper'

describe Bitstat::DataProviders::Physpages do
  describe '#new' do

  end

  describe '#regenerate' do
    let(:physpages) { Bitstat::DataProviders::Physpages.new("#{APP_DIR}/spec/unit/resources/resources") }
    it 'works' do
      pp physpages.regenerate
      pp physpages.vpss
    end
  end
end