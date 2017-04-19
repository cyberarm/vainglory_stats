require "pp"
require "bundler"
Bundler.require

API_KEY = open("#{Dir.pwd}/apikey").read.strip
$api_interface = GameLockerAPI.new(API_KEY)

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
      telemetry = GameLockerAPI::Telemetry.new(params[:telemetry_url])
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
      @match_data = match[:data]
    end

    slim :"matches/index"
  end
  post do
    redirect "/matches/#{params[:match_uuid]}"
  end

  get "/:match_uuid" do
    match = $api_interface.match(params[:match_uuid])
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
    list  = $api_interface.players([params[:playername]])
    if list[:response].code == 429
      @player_data = nil
    elsif list[:response].code != 200
      @player_data = nil
    else
      @player_data = list[:data].first
    end

    match_list  = $api_interface.matches({"filter[playerNames]" => params[:playername], "filter[createdAt-start]" => Time.parse((Time.now-12*(60*60)).to_s).utc.iso8601})
    if match_list[:response].code == 429
      @match_data = nil
    elsif match_list[:response].code != 200
      @match_data = nil
    else
      @match_data = match_list[:data]
    end
    slim :"players/show"
  end
end
