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

	# set @members before visiting members
	if request.path =~ /members/ then
		@members = []
		$redis.zrange("members:ids", 0, -1, withscores: true).map(&:first).each do|id|
			@members << $redis.hgetall("member:#{id}")	
		end
	end
end

# front
get '/' do
	@home = $redis.hgetall('home')
  slim :index, layout: :layout_front
end

get '/members' do
	slim :members, layout: :layout_front
end

# admin
# index
get '/admin/home' do
	@home = $redis.hgetall("home")
	slim :admin_home
end

post '/admin/home' do
	$redis.hmset("home",
							 "image_url", params[:image_url], 
							 "intro", params[:intro])
	redirect('/admin/home')
end

# ---------------

# members
get '/admin/members' do
	slim :admin_members
end

post '/admin/members' do
	members = $redis.zrange("members:ids", 0, -1, withscores: true) 
	id   = (members.map(&:first).max || 1).to_i + 1 
	sort = (members.map(&:last).max || 1).to_i + 1
	$redis.zadd("members:ids", sort, id)
	$redis.hmset("member:#{id}",
							 "id", id,
							 "image_url", params[:member_image],
							 "name", params[:member_name],
							 "intro", params[:member_intro])
	slim :admin_members
end

get '/admin/member/new' do
	@member = {}
	slim :admin_member
end

get '/admin/member/edit/:id' do
	@member = $redis.hgetall("member:#{params[:id]}")	
	slim :admin_member
end

get '/admin/member/delete/:id' do 
	$redis.del("members:#{params[:id]}")
	$redis.zrem("members:ids", params[:id])
	redirect('/members')
end

# helpers
helpers do
	def nav(str=nil)
		request.path.start_with?(str) ? 'active' : '' 
	end
end
