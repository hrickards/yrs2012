require 'rubygems'
require 'bundler'
require 'open-uri'
Bundler.require

@connection = Mongo::Connection.new
@db = @connection['fud']
@collection = @db['places']
@collection.remove

@ratings_collection = @db['raw_ratings']
@google_places_collection = @db['raw_places']

def one_of_in(arr1, arr2)
  arr1.inject(false) { |result, element| result or arr2.include? element }
end

def word_includes_word(word, str)
  str.include? word or str.include? (word << 's') or str.include? word[0..-2]
end

def words_include_word(words, str)
  words.inject (false) { |result, obj| result or word_includes_word(obj, str) }
end

def in_photo_map(str)
  maps = {
    :Mcd => ['mcdonalds', 'maccy ds', 'mcd', 'donald', 'mc', 'donalds'],
    :bbq => ['bbq', 'barbecue', 'grill'],
    :cofe => ['coffee', 'cofe', 'starbucks', 'costa', 'nero', 'republic', 'tea'],
    :fortune_cookie => ['chinese', 'chineese'],
    :hotdog => ['hotdog', 'dog', 'sausage', 'saussage'],
    :myicon => ['burger'],
    :organic => ['organic', 'salad'],
    :pile => ['chicken', 'meat', 'beef', 'lamb', 'pork'],
    :pizza => ['pizza', 'pizzas', 'dominoes', 'dominoes'],
    :sandvi4 => ['sanwich', 'sandwhich', 'bread', 'sandwhiches'],
    :steak => ['steak', 'steaks'],
    :sushi => ['japanese', 'sushi', 'fish'],
    :texmex => ['texan', 'mexican', 'chili', 'fajita'],
    :thai => ['thai']
  }

  results = maps.select { |icon, words| words_include_word words, str }.map { |i, w| i.to_s }.first
end

def magic_photos(details)
  interesting_fields = [details["BusinessName"], details["BusinessType"]].concat (details["types"] or [])
  stop_words = %w{and after caterers other}

  interesting_fields.select { |f| not f.nil? }.map { |f| f.split(" ") }.flatten.map { |f| f.downcase.split(//).select { |s| s =~ /[a-zA-Z]/}.join }.select { |f| not (f.nil? or f.empty? or stop_words.include? f) }.map { |f| in_photo_map f }.select { |f| not f.nil? }.first or 'sandvi4'
end

def allergy_rating
  Random.rand(4)+1
end

def allergy_ratings
  ratings_types = %w{peanuts dairy wheat fish_sesame tree_nuts eggs_gluten shellfish soy}
  ratings = {}
  ratings_types.each do |type|
    if Random.rand(104) > 69
      ratings[type.to_sym] = allergy_rating
    end
  end
  ratings
end

def random_review
  {
    :aspects => [
      {
        :rating => Random.rand(5),
        :type => 'overall'
      }
    ],
    :author_name => Faker::Name.name,
    :text => Faker::Lorem.paragraph,
    :time => Time.now.to_i + ((Random.rand(1) == 0 ? 1 : (-1))*Random.rand(1814400))
  }
end

def s_to_sym(s)
  if s.is_a? Symbol
    s
  else
    s.gsub(" ", "_").gsub(/(.)([A-Z])/,'\1_\2').downcase.to_sym
  end
end

def magic_fix(obj)
  if obj.is_a? String
    s_to_sym obj
  elsif obj.is_a? Array
    obj.map { |o| magic_fix o }
  elsif obj.is_a? Hash
    Hash[obj.map { |k, v| [magic_fix(k), v] } ]
  else
    obj
  end
end

@ratings_collection.find.each do |place|
  next unless place["Geocode"]

  details = place.clone
  details["location"] = 
    {
      :latitude => place["Geocode"].last,
      :longitude => place["Geocode"].first
    }
  details.delete "Geocode"

  address = place["AddressLine1"].split(' ').first.split('/').first.gsub(',', '')
  # Within 5 m
  near_places = @google_places_collection.find({ 'location' => {'$near' => place["Geocode"], '$maxDistance' => 0.00004504 } }).find
  same_place = near_places.nil? ? nil : near_places.select { |p| p["formatted_address"].split(' ').first.split('/').first.gsub(',', '') == address }.select { |p| one_of_in p["name"].split(" "), place["BusinessName"].split(" ") }.first
  unless same_place.nil?
    same_place.delete "location"
    details.merge! same_place
  end

  details["reviews"] = (0..(Random.rand(10)+1)).map { |f| random_review } unless details["reviews"]
  details["allergies"] = allergy_ratings
  details["logo"] = magic_photos details
  if details["logo"] and details["logo"] != "sandvi4"
    puts details["logo"]
  end

  details =  magic_fix Hash[details.select { |key, value| not (key == "_id" or value.nil? or (value.is_a? String and value.empty?)) }]
  @collection.insert details
end
