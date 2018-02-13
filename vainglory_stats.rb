require "pp"
require "bundler"
Bundler.require

if File.exists?("#{Dir.pwd}/apikey")
  API_KEY = open("#{Dir.pwd}/apikey").read.strip
elsif ENV["VAINGLORY_API_KEY"]
  API_KEY = ENV["VAINGLORY_API_KEY"]
else
  raise "No Api Key Given!"
end
$api_interface = GameLockerAPI.new(API_KEY)

PLAYERS = {}
MATCHES = {}
TIME_TO_LIVE = 320 # seconds

def clean_caches
  PLAYERS.each do |key, value|
    if Time.now-value[:time] >= TIME_TO_LIVE
      puts "Player #{key} expired. Was #{Time.now-value[:time]} seconds old."
      PLAYERS.delete(key)
    end
  end
  MATCHES.each do |key, value|
    if Time.now-value[:time] >= TIME_TO_LIVE
      puts "Match #{key} expired. Was #{Time.now-value[:time]} seconds old."
      MATCHES.delete(key)
    end
  end
end

get "/" do
  slim :"home/index"
end
get "/about" do
  slim :"home/about"
end

namespace "/reserved" do
  get do
    "null"
  end

  get "/application.css" do
    sass :application
  end
end

namespace "/telemetry" do
  get do
    if params[:telemetry_url]
      telemetry = $api_interface.telemetry(params[:telemetry_url])
      @telemetry_data = telemetry
    end
    slim :"matches/telemetry"
  end
end

namespace "/matches" do
  get do
    match = $api_interface.match
    if match[:response].code == 429
      @match_data = nil
    elsif match[:response].code != 200
      @match_data = nil
    else
      @match_data = match[:data].reverse
    end

    slim :"matches/index"
  end
  post do
    redirect "/matches/#{params[:match_uuid]}"
  end

  get "/:match_uuid" do
    match = nil
    clean_caches
    if MATCHES[params[:match_uuid]]
      match = MATCHES[params[:match_uuid]][:data]
    else
      _match = $api_interface.match(params[:match_uuid])
      MATCHES[params[:match_uuid]] = {data: _match, time: Time.now}
      match = _match
    end
    if match[:response].code == 429
      @match_data = nil
    elsif match[:response].code != 200
      @match_data = nil
    else
      @match_data = match[:data]
    end

    slim :"matches/show"
  end
end

namespace "/players" do
  get do
    slim :"players/index"
  end
  post do
    redirect "/players/#{params[:playername]}"
  end

  get "/:playername" do
    clean_caches
    list = nil
    if PLAYERS[params[:playername]]
      list = PLAYERS[params[:playername]][:data]
    else
      _list  = $api_interface.players([params[:playername]])
      PLAYERS[params[:playername]] = {data: _list, time: Time.now}
      list = _list
    end
    if list[:response].code == 429
      @player = nil
    elsif list[:response].code != 200
      @player = nil
    else
      @player = list[:data].first
    end

    match_list  = $api_interface.matches({"filter[playerNames]" => params[:playername], "filter[createdAt-start]" => Time.parse((Time.now-12*(60*60)).to_s).utc.iso8601})
    if match_list[:response].code == 429
      @match_data = nil
    elsif match_list[:response].code != 200
      @match_data = nil
    else
      @match_data = match_list[:data].reverse
    end
    slim :"players/show"
  end
end
