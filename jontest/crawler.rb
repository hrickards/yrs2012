require 'net/http'

Net::HTTP.get_print 'ratings.food.gov.uk', '/search/^/^/json'