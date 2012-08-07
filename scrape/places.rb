require 'rubygems'
require 'bundler'
require 'open-uri'
Bundler.require

@connection = Mongo::Connection.new
@db = @connection['fud']
@collection = @db['raw_places']
@collection.remove

@read_collection = @db['raw_ratings']
i = 0

catch :done_enough do
  @read_collection.find.each do |place|
    if place['Geocode']
      location = place['Geocode'].reverse.join ','
      sensor = false
      types = 'food'
      key = 'AIzaSyA4_MbXZb7jP5e9luRnPZRzZuvJOMyRuVM'
      rankby = 'distance'

      url = "https://maps.googleapis.com/maps/api/place/search/json?key=#{key}&location=#{location}&sensor=#{sensor}&rankby=#{rankby}&types=#{types}"
      response = JSON.parse open(url).read
      if response["status"] == "OK"
        response["results"].each do |result|
          details_url = "https://maps.googleapis.com/maps/api/place/details/json?key=#{key}&reference=#{result['reference']}&sensor=#{sensor}"
          details = JSON.parse(open(details_url).read)['result']
          details["location"] = [details["geometry"]["location"]["lng"], details["geometry"]["location"]["lat"]]
          details.delete "geometry"
          @collection.insert details
          puts "Inserting #{i}"
          i += 1

          throw :done_enough if i > 30      
        end
      end
    end
  end
end

@collection.ensure_index [["location", Mongo::GEO2D]]
