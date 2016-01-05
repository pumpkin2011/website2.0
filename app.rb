# require 'rubygem'
require 'bundler/setup'
# require 'slim'
require 'sinatra'
require 'pry'
# require 'pry'
require 'hiredis'
require 'redis'

def setup_redis
  # uri = URI.parse('redis://127.0.0.1:6379') #10000
  $redis = Redis.new(:host => 'localhost', :port => 6379, driver: :hiredis) unless $redis
end

before do
  setup_redis
end

get '/' do
  # binding.pry
  @content = $redis.get('b')
  erb :index
end
