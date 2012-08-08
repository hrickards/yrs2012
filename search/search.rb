require 'fast_stemmer'
require 'text'
require 'sinatra/base'
require 'json'
require 'uri'
require 'open-uri'

# See http://www.ruby-forum.com/topic/59614
class Regexp
  def +(re)
    Regexp.new self.to_s + re.to_s
  end
end

class PlaceSearch
  RESTAURANT_TYPES = %w{mcdonalds bbq coffee donoughts cafe chinese hotdog burger organic chicken pizza sandwhich steak japanese mexican thai indian bar}
  RESTAURANT_WORDS = %w{restaurant place}
  LOCATION_WORDS = %w{near located}
  START_STOP_WORDS = %w{find search me a an one some few}
  STOP_STOP_WORDS = %w{that is also that's}
  IGNORE_MODIFIERS = %w{very relatively quite really}

  LEV_LENGTH_COEFFICIENT = 1/4

  SEARCH_MAPPINGS = {
    %w{healthy} => {'rating_value' => {'$gt' => 3}},
    %w{cheap} => {},
    %w{nut free} => {'allergies.peanuts' => {'$lt' => 3}}
  }

  STEMMED_START_STOP_WORDS = START_STOP_WORDS.map { |word| word.stem }
  STEMMED_STOP_STOP_WORDS = STOP_STOP_WORDS.map { |word| word.stem }
  STEMMED_RESTAURANT_TYPES = RESTAURANT_TYPES.map { |word| word.stem }
  STEMMED_RESTAURANT_WORDS = RESTAURANT_WORDS.map { |word| word.stem }
  STEMMED_LOCATION_WORDS = LOCATION_WORDS.map { |word| word.stem }
  STEMMED_IGNORE_MODIFIERS = IGNORE_MODIFIERS.map { |word| word.stem }
  STEMMED_SEARCH_MAPPINGS = Hash[SEARCH_MAPPINGS.map { |key, value| [key.map { |w| w.stem }, value] }]

  def self.search(string)
    words = pre_parse(string)
    pre_criteria, type, criteria = pivot_type words

    query = { :icon => type }

    query.merge! parse_pre_criteria(pre_criteria)
    query.merge! parse_criteria(criteria)
   
    query
  end

  protected
  def self.parse_criteria(criteria)
    query = {}
    if approx_includes LOCATION_WORDS, criteria.first
      p_i = criteria.index { |x| approx_includes STEMMED_STOP_STOP_WORDS, x }

      if p_i.nil?
        location_criteria = criteria
      else
        location_criteria = criteria[1...p_i]
        criteria = criteria[p_i..-1]
        query.merge! parse_generic_criteria(criteria, STEMMED_STOP_STOP_WORDS)
      end
      query.merge! create_location_criteria(location_criteria.join(' '))
    else
      query.merge! parse_generic_criteria(criteria, STEMMED_STOP_STOP_WORDS)
    end
  end

  def self.parse_pre_criteria(criteria)
    parse_generic_criteria criteria, STEMMED_START_STOP_WORDS
  end

  def self.create_location_criteria(location_criteria)
    location_criteria << ', Brighton'

    base = "http://maps.googleapis.com/maps/api/geocode/json"
    sensor = false
    address = URI.encode location_criteria

    url = "#{base}?sensor=#{sensor}&address=#{address}"
    response = JSON.parse open(url).read

    if response["status"] == "OK"
      details = response["results"].first["geometry"]["location"]
      { 'machine_location' =>
        {
          '$near' => [details["lng"], details["lat"]]
        }
      }
    else
      {}
    end
  end

  def self.criterion_to_querion(criterion)
    if approx_includes STEMMED_LOCATION_WORDS, criterion.first
      create_location_criteria criterion[0..-1]
    else
      criterion = criterion.select { |c| not approx_includes STEMMED_IGNORE_MODIFIERS, c }
      STEMMED_SEARCH_MAPPINGS.select { |key, value| approx_includes [key.join(' ')], criterion.join(' ') }.map { |key, value| value }.first
    end
  end

  def self.parse_generic_criteria(criteria, list_of_things)
    pivot_index = criteria.length - criteria.map { |word| approx_includes list_of_things, word }.reverse.index { |w| w }
    criteria = criteria[pivot_index..-1]
    criteria = criteria.map { |w| w.split(//).last == ',' ? [w.split(//)[0..-2].join(''), ','] : w }.flatten
    criteria = criteria.chunk { |x| x == 'and' or x == ',' }.map { |x| x.last }.select { |x| x != ['and'] and x != [','] }
    merge_array_to_hash(criteria.map { |criterion| criterion_to_querion criterion })
  end

  def self.remove_non_spaceyalphanumeric(string)
    #string.gsub!(/[-.&]/, ' ')
    #string.split(//).select { |char| char =~ /[a-zA-Z0-9 ]/ }.join ''
    string
  end

  def self.stem_words(string)
    string.split(' ').map { |word| word.stem }
  end

  def self.pre_parse(string)
    string = remove_non_spaceyalphanumeric string
    string.downcase!
    stem_words string
  end

  def self.approx_includes(array, string1)
    string1 = string1.split(//)[0..-2].join('') if string1.split(//).last == "'"
    array.map { |string2| Text::Levenshtein.distance string1, string2 }.min <= (string1.length * LEV_LENGTH_COEFFICIENT)
  end
  
  def self.merge_array_to_hash(array)
    array.inject ({}) { |result, value| result.merge value }
  end

  def self.pivot_type(words)
    pivot_index = words.map { |word| approx_includes STEMMED_RESTAURANT_TYPES, word }.index { |w| w }

    descriptions = words[0...pivot_index]
    type = words[pivot_index]
    criteria = remove_restaurant_words words[pivot_index+1..-1]

    [descriptions, type, criteria]
  end
  
  def self.remove_restaurant_words(words)
    if approx_includes (STEMMED_RESTAURANT_WORDS + RESTAURANT_WORDS), words.first
      words[1..-1]
    else
      words
    end
  end
end

class PlaceSearchApi < Sinatra::Base
  post '/search' do
    redirect "http://localhost:8888/yrs2012/?s=#{URI.encode(PlaceSearch.search(params[:query]).to_json)}"
  end
end
