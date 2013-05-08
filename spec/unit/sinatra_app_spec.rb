require 'spec_helper'

set :environment, :test

describe Bitstat::SinatraApp do
  include Rack::Test::Methods

  def app
    Bitstat::SinatraApp
  end

  describe 'callback' do
    let!(:action)   { 'blah'}
    let!(:callback) { double() }
    let!(:data)     { { 'a' => 'b' } }

    before { Bitstat::SinatraApp.set_callback(callback) }

    it 'receives returns action' do
      callback.should_receive(:call)
      post '/', :action => action, :data => data.to_json
    end
  end
end