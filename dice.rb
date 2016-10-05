require 'sinatra'
require 'dalli'
require 'oga'
require 'curb'

$cache = Dalli::Client.new("localhost:11211", { namespace: "dice" })

def get_odds
  cached_odds, date = $cache.get("odds")

  return cached_odds if date && date > Time.new.to_i - 60 * 10

  odds = scrape_odds
  $cache.set("odds", [odds, Time.new.to_i])
  odds
end

def scrape_odds
  puts "scraping odds..."
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

  total = out.values.reduce(:+)
  p out
  out.keys.each do |k|
    out[k] = out[k] / total
  end

  out
end

def random_choice(odds)
  dice_roll = Random.rand

  odds.each_key do |k|
    if dice_roll < odds[k]
      return k
    end
    dice_roll -= odds[k]
  end

  fail
end

get '/' do
  odds = get_odds

  @winner = random_choice(odds)

  candidates = {
    "Trump" => [
      "http://www.slate.com/content/dam/slate/blogs/moneybox/2015/08/16/donald_trump_on_immigration_build_border_fence_make_mexico_pay_for_it/483208412-real-estate-tycoon-donald-trump-flashes-the-thumbs-up.jpg.CROP.promo-xlarge2.jpg",
      "http://i2.cdn.turner.com/cnnnext/dam/assets/150827102252-donald-trump-july-10-2015-super-169.jpg",
      "http://media.washtimes.com.s3.amazonaws.com/media/image/2015/07/13/TRUMP.jpg",
      "http://www.slate.com/content/dam/slate/articles/news_and_politics/politics/2016/04/160422_POL_Donald-Trump-Act.jpg.CROP.promo-xlarge2.jpg",
      "http://www.slate.com/content/dam/slate/articles/news_and_politics/politics/2016/03/160307_POL_Donald-Trump.jpg.CROP.promo-xlarge2.jpg",
    ],
    "Clinton" => [
      "http://media.salon.com/2016/04/aptopix-dem-2016-clinton.jpeg8-1280x960.jpg",
      "https://thenypost.files.wordpress.com/2016/03/dem_2016_clinton-4.jpg",
      "https://qzprod.files.wordpress.com/2016/07/ap_16187600590728-e1469556541505.jpg",
      "https://peskytruth.files.wordpress.com/2016/08/hillary-angry.jpg",
      "http://static.politico.com/b5/ca/803ad5b44ad98e494a52c5b67459/150929-hillary-clinton-gty-629.jpg"
    ],
    "Johnson" => [
      "http://thelibertarianrepublic.com/wp-content/uploads/2016/03/Gary-Johnson.jpg"
    ],
    "Stein" => [
      "https://static01.nyt.com/images/2012/07/13/us/GREEN/GREEN-superJumbo.jpg"
    ]
  }

  @image = candidates[@winner].sample

  erb :index
end

