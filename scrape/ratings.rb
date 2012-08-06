require 'rubygems'
require 'bundler'
require 'open-uri'
Bundler.require

@connection = Mongo::Connection.new
@db = @connection['fud']
@collection = @db['raw_ratings']
@collection.remove

XML_PATH = "FHRS875en-GB.xml"
XML_URL = "http://ratings.food.gov.uk/OpenDataFiles/FHRS875en-GB.xml"
Crack::XML.parse(open(XML_PATH))["FHRSEstablishment"]["EstablishmentCollection"]["EstablishmentDetail"].each do |place|
  if place["Geocode"]
    place["Geocode"]["Longitude"] = place["Geocode"]["Longitude"].to_f
    place["Geocode"]["Latitude"] = place["Geocode"]["Latitude"].to_f
  end
  @collection.insert place
end

@collection.ensure_index [["Geocode", Mongo::GEO2D]]
