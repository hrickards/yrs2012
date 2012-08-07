
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
      base = "http://local.yahooapis.com/LocalSearchService/V3/localSearch"
      appid = "u81yQF3c"
      query = "*"
      sort = "distance"
      radius = 0.001
      latitude = place['Geocode'].last
      longitude = place['Geocode'].first
      output = "json"
      url = "#{base}/?appid=#{appid}&query=#{query}&sort=#{sort}&radius=#{radius}&latitude=#{latitude}&longitude=#{longitude}&output=#{output}"
      raise

      raise url.inspect
    end
  end
end

@collection.ensure_index [["location", Mongo::GEO2D]]
