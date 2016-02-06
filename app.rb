# require 'rubygem'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'pry'
require 'hiredis'
require 'redis'
require 'qiniu'
# require 'json'

def setup_redis
  # uri = URI.parse('redis://127.0.0.1:6379') #10000
  $redis = Redis.new(:host => 'localhost', :port => 6379, driver: :hiredis) unless $redis
end

before do
  setup_redis

	#qiniu
	Qiniu.establish_connection! :access_key => 'lodTWhr36v_H1tx_YKNuCq1kgn2JluMGsx5iytzd',
															:secret_key => 'FmLqr6BK9x_-Y3ktPgdD1Ve8ng9PCnOvBnc752Et'

	# set @members before visiting members
	if request.path =~ /members/ then
		@members = []
		$redis.zrange("members:ids", 0, -1, withscores: true).map(&:first).each do|id|
			@members << $redis.hgetall("member:#{id}")
		end
	end
end

# qiniu uptoken
get '/qiniu/token' do
	put_policy = Qiniu::Auth::PutPolicy.new('loab')
	uptoken = Qiniu::Auth.generate_uptoken(put_policy)
	{"uptoken" => uptoken}.to_json
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

get '/admin' do
	redirect('/admin/home')
end

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

post '/admin/member' do
	members = $redis.zrange("members:ids", 0, -1, withscores: true)
	id   = (members.map(&:first).max || 1).to_i + 1
	sort = (members.map(&:last).max || 1).to_i + 1
	$redis.zadd("members:ids", sort, id)
	$redis.hmset("member:#{id}",
							 "id", id,
							 "image_url", params[:member_image],
							 "name", params[:member_name],
							 "intro", params[:member_intro])
	redirect('/admin/members')
end

get '/admin/member/new' do
	@member = {}
	slim :admin_member
end

get '/admin/member/edit/:id' do
	@member = $redis.hgetall("member:#{params[:id]}")
	slim :admin_member
end

put '/admin/member' do
	$redis.hmset("member:#{params[:member_id]}",
							 "id", params[:member_id],
							 "image_url", params[:member_image],
							 "name", params[:member_name],
							 "intro", params[:member_intro])
	redirect('/admin/members')
end

get '/admin/member/delete/:id' do
	$redis.del("member:#{params[:id]}")
	$redis.zrem("members:ids", params[:id])
	redirect('/admin/members')
end

# helpers
helpers do
	def nav(str=nil)
		request.path =~ /#{str}/ ? 'active' : ''
	end
end
