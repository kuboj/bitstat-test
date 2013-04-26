require 'spec_helper'

describe Bitstat::HttpServer do
  describe 'input options' do
    it 'takes hash as argument with keys :port, :app_class and :callback' do
      expect { Bitstat::HttpServer.new(:port => 1, :app_class => nil) }.to raise_error(IndexError)
      expect { Bitstat::HttpServer.new(:port => 1, :app_class => nil, :callback => nil) }.not_to raise_error
    end
  end
end