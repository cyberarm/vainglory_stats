require_relative "lib/gamelocker_api"
require "oj"

GameLockerAPI::AbstractParser.guess("matches", Oj.load(open(Dir.pwd+"/response.dat").read))
