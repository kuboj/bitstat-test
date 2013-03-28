require 'rubygems'
require 'bundler'
require 'yaml'
Bundler.require(:default)

APP_DIR = File.expand_path("#{File.dirname(__FILE__)}/../")
Thread.abort_on_exception = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bitstat/version'
require 'bitstat/vestat'
require 'bitstat/vzlist'
require 'bitstat/cpubusy'

module Bitstat

end
