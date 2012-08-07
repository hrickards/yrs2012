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

def s_to_sym(s)
  s.gsub(" ", "_").gsub(/(.)([A-Z])/,'\1_\2').downcase.to_sym
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
      :latitude => place["Geocode"].first,
      :longitude => place["Geocode"].last
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

  details =  magic_fix Hash[details.select { |key, value| not (key == "_id" or value.nil? or (value.is_a? String and value.empty?)) }]
  @collection.insert details
end
