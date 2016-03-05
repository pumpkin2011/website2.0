# require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'slim'
require 'pry'
require 'hiredis'
require 'redis'
require 'qiniu'
require 'json'

def setup_redis
	# uri = URI.parse('redis://127.0.0.1:6379') #10000
	$redis = Redis.new(:host => 'localhost', :port => 6379, driver: :hiredis) unless $redis
end

before do
	setup_redis

	#qiniu
	Qiniu.establish_connection! :access_key => 'lodTWhr36v_H1tx_YKNuCq1kgn2JluMGsx5iytzd',
		:secret_key => 'FmLqr6BK9x_-Y3ktPgdD1Ve8ng9PCnOvBnc752Et'

	# set @members and @papers before visiting index 
	%w(member paper).each do |name|
		plural_name = name + 's'
		if request.path.include?(plural_name) then
			instance_name = "@#{plural_name}"
			ids = $redis.zrange("#{name}:ids", 0, -1, withscores: true).map(&:first)
			values = $redis.hgetall(plural_name).values.map!{|item| eval item }
			values = values.sort_by { |a| ids.index(a[:id].to_s) }
			instance_variable_set(instance_name, values) 
		end
	end

=begin
	if request.path =~ /members/ then
		@members = []
		$redis.zrange("member:ids", 0, -1, withscores: true).map(&:first).each do|id|
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
=end
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
	create_or_update_record('member', %w(id image_url name intro))
end

get '/admin/member/edit/:id' do
	@member = eval $redis.hget("members", "member:#{params[:id]}")
	slim :admin_member
end

put '/admin/member' do
	create_or_update_record('member', %w(id image_url name intro))
end

get '/admin/member/delete/:id' do
	delete_record('member', params[:id])
end

# -------------------

# papers
get '/admin/papers' do
	slim :admin_papers
end

get '/admin/paper/new' do
	@paper = {}
	slim :admin_paper
end

post '/admin/paper' do
	create_or_update_record('paper', %w(id date content))
end

get '/admin/paper/edit/:id' do
	@paper = eval $redis.hget("papers", "paper:#{params[:id]}")
	slim :admin_paper
end

put '/admin/paper' do
	create_or_update_record('paper', %w(id date content))
end

get '/admin/paper/delete/:id' do
	delete_record('paper', params[:id])
end

# -----------------

# helpers
helpers do
	def nav(str=nil)
		request.path =~ /#{str}/ ? 'active' : ''
	end
end

# --------------------

private
# create a new record
def create_or_update_record(name, arr)
	plural_name = "#{name}s"
	ids  = $redis.zrange("#{name}:ids", 0, -1, withscores: true)
	if params[:id].empty? then
		id   = (ids.map(&:first).max || 0).to_i + 1
		sort = (ids.map(&:last).max || 0).to_i + 1
		$redis.zadd("#{name}:ids", sort, id)
	end
	values = arr.map{ |item| params[item.to_sym] }
	data = arr.zip(values).to_h
	data["id"] = Integer(params[:id]) rescue id
	$redis.hmset(plural_name, "#{name}:#{data['id']}", data)
	redirect("/admin/#{plural_name}")
end

# delete a record
def delete_record(name, id)
	plural_name = "#{name}s"
	$redis.hdel(plural_name, "#{name}:#{id}")
	$redis.zrem("#{name}:ids", id)
	redirect("/admin/#{plural_name}")
end

