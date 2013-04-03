require 'rubygems'
require 'bundler'
require 'yaml'
require 'observer'
Bundler.require(:default)

APP_DIR = File.expand_path("#{File.dirname(__FILE__)}/../")
Thread.abort_on_exception = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bitstat/call_filter'
require 'bitstat/collector'
require 'bitstat/version'

require 'bitstat/data_providers/cpubusy'
require 'bitstat/data_providers/vestat'
require 'bitstat/data_providers/vzlist'

require 'bitstat/watchers/average'
require 'bitstat/watchers/down'
require 'bitstat/watchers/up'

module Bitstat

end
