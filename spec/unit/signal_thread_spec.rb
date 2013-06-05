require 'spec_helper'

describe Bitstat::SignalThread do
  describe '#new' do
    it 'works' do
      notified_object = double
      st = Bitstat::SignalThread.new { notified_object.notify }
      notified_object.should_receive(:notify).exactly(3).times
      st.signal
      st.signal
      st.signal
      sleep(0.5)
    end
  end
end