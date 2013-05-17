class Thread
  def signal
    @signal = true
    run
  end

  def wait_for_signal
    Thread.stop until (@signal ||= false)
    @signal = false
  end
end