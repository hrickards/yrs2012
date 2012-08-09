require 'sinatra/base'
require_relative 'search'
require_relative 'mobile'

class FUDBackend < Sinatra::Base
  post '/search' do
    query = params[:query]
    results = PlaceSearch.search_wrapper query
    is_me = results['location']
    results.delete 'location'
    
    referer = request.referer or "http://localhost:8888/yrs2012/"
    redirect "#{referer}?s=#{URI.encode(query)}&q=#{URI.encode(results.to_json)}&me=#{is_me}"
  end
  
  get '/search' do
    results = PlaceSearch.search_wrapper(params[:query])
    results.delete 'location'
    results.to_json
  end

  get '/sms' do
    content_type :xml
    MobileSearch.sms params[:Body]
  end

  get '/voice' do
    content_type :xml
    MobileSearch.voice
  end

  get '/handle_voice' do
    content_type :xml
    MobileSearch.handle_voice params["RecordingUrl"], params["To"], params["From"]
  end
end
