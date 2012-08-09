require 'mongo'
require 'twilio-ruby'
require 'sinatra/base'

require_relative '../search/search'

class FUDMobile < Sinatra::Base
  post '/sms' do
    content_type 'text/plain'

    query = PlaceSearch.search_wrapper params[:body]
    puts query.inspect
    humanised_query = "#{query[:logo]} " if query[:logo]
    header = "FUD found you the following #{humanised_query}restaurants:\n"

    @connection = Mongo::Connection.new
    @db = @connection['fud']
    @collection = @db['places']
    results = @collection.find(query).limit(5)

    results = results.map { |p| "#{p["business_name"]}, near #{p["address_line1"]}" }.join "\n"

    header + results
  end
end
