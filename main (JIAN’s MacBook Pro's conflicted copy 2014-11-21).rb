require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do 
  def calculate_total(cards) 
  # [['H', '3'], ['S', 'Q'], ... ]
    arr = cards.map{|e| e[1] }

    total = 0
    arr.each do |value|
      if value == "ace"
        total += 11
      elsif value.to_i == 0 # jack, queen, king
        total += 10
      else
        total += value.to_i
      end
    end

    #correct for Aces
    arr.select{|e| e == "ace"}.count.times do
      total -= 10 if total > 21
    end

    total
  end

  def display(card)
    "/images/cards/" + card[0] + "_" + card[1] + ".jpg"
  end

  def blackjack?(cards)
    calculate_total(cards) == 21
  end

  def busted?(cards)
    calculate_total(cards) > 21
  end
end

get '/' do 
  session[:player_name] ? (redirect '/game') : (redirect '/new_player')
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do 
  suits = ["hearts", "spades", "diamonds", "clubs"]
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']
  session[:deck] = suits.product(cards).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
  2.times do 
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop  
  end 
  erb :game
end

post '/game/player/hit' do
  if blackjack?(session[:player_cards])
    #hit blackjack
  elsif busted?(session[:player_cards])
    #busted
  else
    session[:player_cards] << session[:deck].pop
  end

  erb :game
end

post '/game/player/stay' do
  # dealer's turn
  erb :game
end