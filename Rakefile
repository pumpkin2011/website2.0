require 'bcrypt'

namespace :admin do
  desc "Creating an admin account by"
  task :create_an_admin, [:username, :password] do |t, arg|
    username = arg[:username]
    password = arg[:password]
    password_salt = BCrypt::Engine.generate_salt
    password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    %x`echo hmset admin username #{username} password #{password_hash} salt #{password_salt} | redis-cli`
    puts "notice: Administrator account was seted successfully."
  end
end
