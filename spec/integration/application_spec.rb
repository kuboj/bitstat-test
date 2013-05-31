require 'spec_helper'

describe Bitstat do
  describe 'application' do
    it 'works' do
      app = Bitstat::Application.new({
          :vestat_path       => nil,
          :vzlist_fields     => nil,
          :nodes_config_path => "#{APP_DIR}/spec/integration/config/nodes.yml",
          :ticker_interval   => 0.1,
          :supervisor_url    => nil,
          :verify_ssl        => false,
          :node_id           => 2
      })

      vzlist = double('vzlist')
      vzlist.stub(:regenerate)
      vzlist.stub(:vpss).and_return(
          {
              1 => { :physpages => 1000, :diskinodes => 2000 },
              2 => { :physpages => 5000, :diskinodes => 1000 }
          }
      )
      app.stub(:vzlist).and_return(vzlist)
      cpubusy = double('cpubusy')
      cpubusy.stub(:regenerate)
      cpubusy.stub(:vpss).and_return(
          {
              1 => { :cpubusy => 85 },
              2 => { :cpubusy => 10 }
          },
          {
              1 => { :cpubusy => 89 },
              2 => { :cpubusy => 20 }
          },
          {
              1 => { :cpubusy => 84 },
              2 => { :cpubusy => 60 }
          }
      )
      app.stub(:cpubusy).and_return(cpubusy)
      app.send(:notify_queue)
      app.instance_variable_get(:@notify_queue).should_receive(:send_notifications).with([[1,:cpubusy, :up, 84], [2, :cpubusy, :average ,30.0]])

      app.reload
      app.start
      sleep 0.3
      app.stop
    end
  end
end