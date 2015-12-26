# require 'rubygem'
# require 'bundler/setup'
require 'slim'
require 'sinatra'

get '/' do
  slim :index
end
