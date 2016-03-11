require 'rubygems'
require 'sinatra'
# require './env.rb' if File.exists?('env.rb')

set :env,:development
disable :run

require './app.rb'

run Sinatra::Application
