require 'rubygems'
require 'bundler'
require 'sinatra'
require 'bundler/setup'
require 'sinatra/flash'
require 'slim'
require 'hiredis'
require 'redis'
require 'qiniu'
require 'json'
require 'active_support/inflector'
require 'bcrypt'
require 'sass'

if development?
  require 'pry'
  require './env.rb' if File.exists?('env.rb')
end

require_relative 'helper/crud'

# Bundler.require

require './app.rb'

# set :env,:development
# set :show_exceptions, :after_handler
# disable :run

run Sinatra::Application
