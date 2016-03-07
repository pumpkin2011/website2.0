# require File.expand_path '../app.rb', __FILE__
# run app

require 'rubygems'  
require 'sinatra'  
  
set :env,:development  
disable :run  
  
require './app.rb'  
  
# 在Sinatra的示例文档中是这样的: run Sinatra.application,但这样会报错的,修改后如下,正确启动.  
run Sinatra::Application  
