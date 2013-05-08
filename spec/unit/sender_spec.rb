require 'spec_helper'

describe Bitstat::Sender do
  describe '#new' do
    it 'takes one hash with mandatory key :url' do
      expect { Bitstat::Sender.new({}) }.to raise_error(IndexError)
      expect { Bitstat::Sender.new(:url => nil) }.not_to raise_error
    end

    it 'takes optional arguments :verify_ssl and :crt_path, :max_retries and :wait_time' do
      expect { Bitstat::Sender.new(:url => nil, :verify_ssl => nil) }.not_to raise_error
    end
  end

  describe '#try' do
    let(:sender) { Bitstat::Sender.new(:url => nil) }

    it 'calls block until it returns true' do
      i = 0
      sender.try(:count => 10, :wait => 0.01) do
        i += 1
        i == 1 ? false : true
      end

      i.should eql 2
    end

    it 'executes block max `count` times' do
      i = 0
      sender.try(:count => 3, :wait => 0.01) do
        i += 1
        false
      end
      i.should eql 3
    end

    it 'rescues given exceptions' do
      class MyException < StandardError; end
      j = 0

      sender.try(:count => 3, :wait => 0.01, :rescue => [MyException]) do |i|
        raise MyException if i == 1
        j = i
      end

      j.should eql 2
    end
  end

  describe '#send' do
    class DummyServer < Sinatra::Base
      post '/halt' do
        $retries += 1
        params[:halt] ? halt(500) : { :a => 1 }.to_json
      end
    end

    describe 'without ssl' do
      before do
        $retries = 0
        $thread = Thread.new do
          Rack::Handler::Thin.run(DummyServer, { :Port => 30000 }) do |server|
            $thin = server
            Thin::Logging.silent = true
          end
        end

        sleep(0.1) until $thin.running?

        @sender = Bitstat::Sender.new(
            :url         => 'http://localhost:30000/halt',
            :max_retries => 5,
            :wait_time   => 0.1
        )
      end

      it 'tries :count times to send data' do
        data = { :halt => 'mnaf' }
        @sender.send(data).should be_nil
        $retries.should eql 5
      end
    end

    describe 'with ssl' do
      before do
        $retries = 0
        $thread2 = Thread.new do
          Rack::Handler::Thin.run(DummyServer, { :Port => 30002 }) do |server|
            $thin2 = server
            Thin::Logging.silent = true
            server.ssl = true
            server.ssl_options = {
                :private_key_file => File.expand_path("#{File.dirname(__FILE__)}/ssl/key"),
                :cert_chain_file  => File.expand_path("#{File.dirname(__FILE__)}/ssl/crt"),
                :verify_peer      => false
            }
          end
        end

        sleep(0.1) until $thin2.running?

        @sender2 = Bitstat::Sender.new(
            :url         => 'https://localhost:30002/halt',
            :max_retries => 5,
            :wait_time   => 0.1
        )
      end

      it 'works' do
        expected = { :a => 1 }
        @sender2.send(false).should eql expected
      end
    end
  end
end