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

  def card_image(card)
    "<img src='/images/cards/#{card[0]}_#{card[1]}.jpg' class='card_image'>"
  end

  def blackjack?(cards)
    calculate_total(cards) == 21
  end

  def busted?(cards)
    calculate_total(cards) > 21
  end

  def dealer_hit_result
    player_cards_total = calculate_total(session[:player_cards])
    dealer_cards_total = calculate_total(session[:dealer_cards])

    if dealer_cards_total >= 17
      @show_dealer_hit_button = false
      @play_again = true
      if busted?(session[:dealer_cards])
        session[:player_money] += session[:bet_amount]
        @success = "Dealer has #{calculate_total(session[:dealer_cards])} and busted! #{session[:player_name]} won! #{session[:player_name]} now has $#{session[:player_money]}."
      elsif blackjack?(session[:dealer_cards])
        session[:player_money] -= session[:bet_amount]
        @error = "Dealer hit blackjack and won! #{session[:player_name]} now has $#{session[:player_money]}."
      else
        if player_cards_total == dealer_cards_total
          @success = "It's a tie! #{session[:player_name]} now has $#{session[:player_money]}."
        elsif player_cards_total > dealer_cards_total
          session[:player_money] += session[:bet_amount]
          @success = "#{session[:player_name]} has #{player_cards_total} and Dealer has #{dealer_cards_total}. #{session[:player_name]} won! #{session[:player_name]} now has $#{session[:player_money]}."
        else
          session[:player_money] -= session[:bet_amount]
          @error = "#{session[:player_name]} has #{player_cards_total} and Dealer has #{dealer_cards_total}. Dealer won! #{session[:player_name]} now has $#{session[:player_money]}."
        end
      end
    end
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do 
  redirect '/new_player'
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  session[:player_money] = 500
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do
  session[:bet_amount] = params[:bet_amount].to_i
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

  if blackjack?(session[:player_cards])
    session[:player_money] += session[:bet_amount]
    @success = "#{session[:player_name]} hit blackjack and won! #{session[:player_name]} now has $#{session[:player_money]}."
    @show_hit_or_stay_buttons = false
    @play_again = true
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if busted?(session[:player_cards])
    session[:player_money] -= session[:bet_amount]
    @error = "#{session[:player_name]} has #{calculate_total(session[:player_cards])} and busted! #{session[:player_name]} now has $#{session[:player_money]}."
    @show_hit_or_stay_buttons = false
    @play_again = true
  end

  if blackjack?(session[:player_cards])
    session[:player_money] += session[:bet_amount]    
    @success = "#{session[:player_name]} hit blackjack and won! #{session[:player_name]} now has $#{session[:player_money]}."
    @show_hit_or_stay_buttons = false
    @play_again = true
  end

  erb :game
end

post '/game/player/stay' do
  @success = session[:player_name] +" has chosen to stay. It's Dealer's turn now."
  @show_hit_or_stay_buttons =false
  @show_dealer_hit_button = true
  @show_dealer_first_card = true

  dealer_hit_result

  erb :game
end

post '/game/dealer/hit' do
  @show_hit_or_stay_buttons =false
  @show_dealer_hit_button = true
  @show_dealer_first_card = true
 
  session[:dealer_cards] << session[:deck].pop
  
  dealer_hit_result

  erb :game
end

get '/game_over' do
  erb :game_over
end





