require 'mongo'
require 'twilio-ruby'
require 'sinatra/base'

require_relative '../search/search'

class FUDMobile < Sinatra::Base
  get '/sms' do
    content_type :xml

    query = PlaceSearch.search_wrapper params[:Body]
    puts query.inspect
    humanised_query = "#{query[:logo]} " if query[:logo]
    header = "FUD found you these #{humanised_query}restaurants:\n"

    @connection = Mongo::Connection.new
    @db = @connection['fud']
    @collection = @db['places']
    results = @collection.find(query).limit(5)

    results = results.map { |p| "#{p["business_name"]}, near #{p["address_line1"]}" }

    twiml = <<EOF
<?xml version="1.0" encoding="UTF-8" ?>  
<Response> 
  <Sms>#{header + results[0..1].join("\n")}</Sms>
  <Sms>#{results[2..-1].join "\n"}</Sms>
</Response>
EOF
  end
end
