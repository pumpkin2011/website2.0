require 'rubygems'
require 'sinatra'
require './app.rb'

# set :env,:development
# set :show_exceptions, :after_handler
# disable :run

run Sinatra::Application
