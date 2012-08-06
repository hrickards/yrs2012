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
Crack::XML.parse(open(XML_PATH))["FHRSEstablishment"]["EstablishmentCollection"]["EstablishmentDetail"].each { |place| @collection.insert place }
