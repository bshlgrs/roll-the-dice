require 'sinatra'
require 'dalli'
require 'oga'
require 'curb'

# $cache = Dalli::Client.new("localhost:11211", { namespace: "dice" })

def get_odds
  # cached_odds, date = $cache.get("odds")

  # return cached_odds if date && date > Time.new.to_i - 60 * 10

  odds = scrape_odds

  # $cache.set("odds", [odds, date])
  odds
end

def scrape_odds
  res = Curl.get("https://electionbettingodds.com/")
  html = Oga.parse_html(res.body_str)

  out = {}

  candidates = %w'Clinton Trump Johnson Stein'

  html.css("img").each do |node|
    candidate = node.get("src")[1..-5]
    if candidates.include?(candidate)
      out[candidate] = node.parent.parent.at_css("p").text.to_f
    end
  end

  out
end

get '/' do
  odds = get_odds

  odds.inspect
end

