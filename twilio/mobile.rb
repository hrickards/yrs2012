require 'mongo'
require 'twilio-ruby'
require 'sinatra/base'
require 'net/http'

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

    <<EOF
<?xml version="1.0" encoding="UTF-8" ?>  
<Response> 
  <Sms>#{header + results[0..1].join("\n")}</Sms>
  <Sms>#{results[2..-1].join "\n"}</Sms>
</Response>
EOF
  end

  get '/voice' do
    content_type :xml

    <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say>
    Please say what you would like to find after the beep.
    Press the start key when finished.
  </Say>
  <Record
    transcribe="true"
    transcribeCallback="/handle_transcription"
    maxLength="30"
    finishOnKey="*"
    method="GET"
    action="/handle_voice"
    />
  <Say>Sorry, I didn't quite catch that</Say>
</Response>
EOF
  end

  get 'handle_voice' do
    content_type :xml

    <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say>
    Thank you. You will shortly get a text with results.
  </Say>
</Response>
EOF
  end

  post 'handle_transcription' do
    from = params['From']
    to = params['To']
    body = params['TranscriptionText']
    account_sid = 'AP2aeed3568cd85567ef10ce168355b0fc'

    url = "http://www.twilio.com/2010-04-01/Accounts/#{account_sid}/SMS/Messages"

    http = Net::HTTP.new
    http.post url, "from=#{from}&to=#{to}&body=#{body}"
  end
end
