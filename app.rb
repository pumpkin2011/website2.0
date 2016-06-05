require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/flash'
require 'slim'
require 'hiredis'
require 'redis'
require 'qiniu'
require 'json'
require 'active_support/inflector'
require 'bcrypt'
if development?
  require 'pry'
  require './env.rb' if File.exists?('env.rb')
end

enable :sessions

before do
  setup_redis
  before_login
  setup_qiniu

  # set @members or @papers
  name = request.path.slice(/members|papers/)
  set_data(name) if name
end

# qiniu uptoken
get '/qiniu/token' do
  put_policy = Qiniu::Auth::PutPolicy.new('loab')
  uptoken = Qiniu::Auth.generate_uptoken(put_policy)
  {"uptoken" => uptoken}.to_json
end

# login
get '/login' do
  slim :login, layout: :layout_front
end

post '/login' do
  admin = $redis.hgetall('admin')
  if admin['username'] == params[:username] &&
     admin['password'] == BCrypt::Engine.hash_secret(params[:password], admin['salt'])
    session[:admin] = params[:username]
    redirect('/admin/home')
  end
  flash[:error] = "Username doesn't match the password"
  redirect('/login')
end

get '/logout' do
  session[:admin] = nil
  redirect('/')
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

get '/research_interests' do
  'Research Interests'
end

get '/contact' do
  'xxx-xxx-xxxx'
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
  create_or_update_record('paper', %w(id date content pdf_url))
end

get '/admin/paper/edit/:id' do
  @paper = eval $redis.hget("papers", "paper:#{params[:id]}")
  slim :admin_paper
end

put '/admin/paper' do
  create_or_update_record('paper', %w(id date content pdf_url))
end

get '/admin/paper/delete/:id' do
  delete_record('paper', params[:id])
end

# -----------------

# helpers
helpers do
  def nav(str=nil)
    request.path =~ /#{str}/ ? 'actived' : ''
  end

  def admin_name
    return session[:admin]
  end
end

# --------------------

private

def setup_redis
  # uri = URI.parse('redis://127.0.0.1:6379') #10000
  $redis = Redis.new(:host => 'localhost', :port => 6379, driver: :hiredis) unless $redis
end

def setup_qiniu
  Qiniu.establish_connection! :access_key => ENV['qiniu_access_key'],
                              :secret_key => ENV['qiniu_secret_key']
end

def before_login
  if request.path=~/admin/ && admin_name.nil? then
    redirect('/login')
  end
end

def auth(param)
  admin = $redis.getall()
end

def set_data(name)
  singular_name = name.singularize
  instance_name = "@#{name}"
  ids = $redis.zrange("#{singular_name}:ids", 0, -1)
  values = $redis.hgetall(name).values.map!{|item| eval item }.sort_by { |a| ids.index(a['id'].to_s) }
  instance_variable_set(instance_name, values)
end

# create or update a record
def create_or_update_record(name, arr)
  plural_name = name.pluralize
  ids  = $redis.zrange("#{name}:ids", 0, -1, withscores: true).to_h
  id, sort = ids.keys.max.to_i+1, ids.values.max.to_i+1 if params[:id].empty?
  data = {}
  arr.each { |item| data[item] = params[item.to_sym] }
  # values = arr.map{ |item| params[item.to_sym] }
  # data = arr.zip(values).to_h
  data["id"] = Integer(params[:id]) rescue id
  # begin
  $redis.zadd("#{name}:ids", sort, id) if params[:id].empty?
  $redis.hmset(plural_name, "#{name}:#{data['id']}", data)
  # rescue
  #   # logger.info "store data failed"
  #   $redis.zrem("#{name}:ids", id) if params[:id].empty?
  #   $redis.hdel(plural_name, "#{name}:#{data['id']}")
  # end
  redirect("/admin/#{plural_name}")
end

# delete a record
def delete_record(name, id)
  plural_name = name.pluralize
  $redis.hdel(plural_name, "#{name}:#{id}")
  $redis.zrem("#{name}:ids", id)
  redirect("/admin/#{plural_name}")
end
