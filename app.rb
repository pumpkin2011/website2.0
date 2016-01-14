# require 'rubygem'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'pry'
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
	@home = $redis.hgetall('home')
  slim :index
end

get '/members' do
	binding.pry
	slim :members
end

# admin
# index
get '/admin/home' do
	slim :admin_home, layout: :layout_admin
end

post '/admin/home' do
	$redis.hmset("home",
							 "image_url", params[:image_url], 
							 "intro", params[:intro])
	slim :admin_home, layout: :layout_admin
end

# ---------------

# members
get '/admin/members' do
	slim :admin_members, layout: :layout_admin
end

post '/admin/members' do
	id = $redis.incr("members.count")
	$redis.hmset("member:#{id}",
							 "id", id,
							 "image_url", params[:member_image],
							 "name", params[:member_name],
							 "gender", params[:member_gender],
							 "intro", params[:member_intro])
	slim :admin_members, layout: :layout_admin
end

# helpers
helpers do
	def nav(str=nil)
		request.path =~ /#{str||'index'}/ ? 'active' : '' 
	end
end
