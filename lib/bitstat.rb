require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require(:default)

APP_DIR = File.expand_path("#{File.dirname(__FILE__)}/../")
Thread.abort_on_exception = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bitstat/version'
require 'bitstat/call_filter'

require 'bitstat/data_providers/cpubusy'
require 'bitstat/data_providers/vestat'
require 'bitstat/data_providers/vzlist'

require 'bitstat/watchers/up'
require 'bitstat/watchers/average'

module Bitstat

end
