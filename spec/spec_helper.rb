require File.dirname(__FILE__) + '/../lib/bitstat'
$LOAD_PATH.unshift(File.dirname(__FILE__))

RSpec.configure do |config|
  config.before(:suite) do
    # redirect logging to /dev/null
    Bitlogger.init({ :target => File.open('/dev/null', 'w') })
  end

  config.color_enabled = true
  config.tty           = true
  config.formatter     = :documentation
end
