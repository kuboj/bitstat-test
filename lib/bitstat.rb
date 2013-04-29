require 'rubygems'
require 'bundler'
require 'yaml'
require 'rack/test'
Bundler.require(:default)

APP_DIR = File.expand_path("#{File.dirname(__FILE__)}/../")
Thread.abort_on_exception = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bitstat/call_filter'
require 'bitstat/collector'
require 'bitstat/cli'
require 'bitstat/controller'
require 'bitstat/http_server'
require 'bitstat/sender'
require 'bitstat/sinatra_app'
require 'bitstat/version'

require 'bitstat/data_providers/cpubusy'
require 'bitstat/data_providers/vestat'
require 'bitstat/data_providers/vzlist'

require 'bitstat/watchers/average'
require 'bitstat/watchers/down'
require 'bitstat/watchers/up'

require 'bitstat/core_ext/object'

module Bitstat

end
