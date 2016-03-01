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

	# set @papers before visiting
	if request.path =~ /papers/ then
		@papers = []
		$redis.zrange("paper:ids", 0, -1, withscores: true).map(&:first).each do |id|
			@papers << $redis.hgetall("paper:#{id}")
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

get '/papers' do
	slim :papers, layout: :layout_front
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

get '/admin/member/new' do
	@member = {}
	slim :admin_member
end

post '/admin/member' do
	members = $redis.zrange("member:ids", 0, -1, withscores: true)
	id   = (members.map(&:first).max || 0).to_i + 1
	sort = (members.map(&:last).max || 0).to_i + 1
	$redis.zadd("members:ids", sort, id)
	$redis.hmset("member:#{id}",
							 "id", id,
							 "image_url", params[:member_image],
							 "name", params[:member_name],
							 "intro", params[:member_intro])
	redirect('/admin/members')
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

# papers
get '/admin/papers' do
	slim :admin_papers
end

get '/admin/paper/new' do
	@paper = {}
	slim :admin_paper
end

post '/admin/paper' do
	papers = $redis.zrange("paper:ids", 0, -1, withscore: true)
	id   = (papers.map(&:first).max || 0) + 1
	sort = (papers.map(&:last).max  || 0) + 1
	$redis.zadd("paper:ids", sort, id)
	$redis.zadd("paper:ids", sort, id)
	$redis.hmset("paper:#{id}",
							 "id", id,
							 "date", params[:paper_date],
							 "content", params[:paper_content])
	redirect('/admin/papers')
end

get '/admin/paper/edit/:id' do
	@paper = $redis.hgetall("paper:#{params[:id]}")
	slim :admin_paper
end

put '/admin/member' do
	$redis.hmset("paper:#{params[:paper_id]}",
							 "id", params[:paper_id],
							 "date", params[:paper_date],
							 "intro", params[:paper_content])
	redirect('/admin/papers')
end

get '/admin/paper/delete/:id' do
	$redis.del("paper:#{params[:id]}")
	$redis.zrem("paper:ids", params[:id])
	redirect('/admin/papers')
end


# helpers
helpers do
	def nav(str=nil)
		request.path =~ /#{str}/ ? 'active' : ''
	end
end
