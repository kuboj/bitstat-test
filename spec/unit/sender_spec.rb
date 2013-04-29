require 'spec_helper'

describe Bitstat::Sender do
  describe '#new' do
    it 'takes one hash with keys :host, :port' do
      expect { Bitstat::Sender.new(:port => 1) }.to raise_error(IndexError)
      expect { Bitstat::Sender.new(:port => 1, :host => '') }.not_to raise_error
    end
  end

  describe '#send' do

  end
end