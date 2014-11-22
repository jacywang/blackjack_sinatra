require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get "/" do 
  erb :new_game
end
