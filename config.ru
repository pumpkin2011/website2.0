require 'rubygems'
require 'sinatra'
require './app.rb'

# set :env,:development
# set :show_exceptions, :after_handler
# disable :run

use Rack::Session::Cookie,
:domain=>'0.0.0.0',
:path => '/'

run Sinatra::Application
