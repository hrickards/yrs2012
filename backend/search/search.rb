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

def open_parse_array(file_name)
  open(file_name).read.split("\n")
end

def open_parse_nested_array(file_name)
  open_parse_array(file_name).map { |l| l.split(" ") }
end

def open_parse_table(file_name)
  Hash[open(file_name).read.split("\n").map { |l| l.split("|").map { |c| c.lstrip.strip }[1..-1] }]
end

class PlaceSearch
  RESTAURANT_TYPES = open_parse_table 'data/restaurant_types'
  RESTAURANT_WORDS = open_parse_nested_array 'data/restaurant_words'
  LOCATION_WORDS = open_parse_array 'data/location_words'
  START_STOP_WORDS = open_parse_array 'data/start_stop_words'
  STOP_STOP_WORDS = open_parse_array 'data/stop_stop_words'
  IGNORE_MODIFIERS = open_parse_array 'data/ignore_modifiers'

  LEV_LENGTH_COEFFICIENT = 1/4

  STEMMED_START_STOP_WORDS = START_STOP_WORDS.map { |word| word.stem }
  STEMMED_STOP_STOP_WORDS = STOP_STOP_WORDS.map { |word| word.stem }
  STEMMED_RESTAURANT_WORDS = RESTAURANT_WORDS.map { |words| words.map { |word| word.stem } }
  STEMMED_LOCATION_WORDS = LOCATION_WORDS.map { |word| word.stem }
  STEMMED_IGNORE_MODIFIERS = IGNORE_MODIFIERS.map { |word| word.stem }
  STEMMED_RESTAURANT_TYPES = Hash[RESTAURANT_TYPES.map { |key, value| [key.stem, value] }]

  def self.search(string)
    words = pre_parse(string)

    pre_criteria, type, criteria = pivot_type words

    query = { :type => type }

    query.merge! parse_pre_criteria(pre_criteria)
    old_filters = query[:filters]
    query.merge! parse_criteria(criteria)
    query[:filters] += old_filters if query[:filters] and old_filters
    
    query
  end

  def self.search_wrapper(string)
    begin
      old_query = search string
      query = {}

      query[:logo] = old_query[:type] if old_query[:type]

      old_query[:filters].each do |filter_name|
        query.merge! (case filter_name
      when 'cheap'.stem
        {}
      when 'nutfree'
        {'allergies.peanuts' => {'$lt' => 3}}
      when 'hygienic'.stem
        {'rating_value' => {'$gt' => 3}}
      else
        {}
      end)
      end if old_query[:filters]

      query.merge! create_location_criteria(old_query[:location]) if old_query[:location]

      query
    rescue Exception
      {}
    end
  end

  protected
  def self.parse_criteria(criteria)
    return {} if criteria.empty?
    query = {}
    if approx_includes LOCATION_WORDS, criteria.first
      p_i = criteria.index { |x| approx_includes STEMMED_STOP_STOP_WORDS, x }

      if p_i.nil?
        location_criteria = criteria[1..-1]
      else
        location_criteria = criteria[1...p_i]
        criteria = criteria[p_i..-1]
        query.merge! parse_generic_criteria(criteria, STEMMED_STOP_STOP_WORDS)
      end
      query.merge! ({:location => location_criteria.join(' ')})
    else
      query.merge! parse_generic_criteria(criteria, STEMMED_STOP_STOP_WORDS)
    end
  end

  def self.parse_pre_criteria(criteria)
    return {} if criteria.empty?
    parse_generic_criteria criteria, STEMMED_START_STOP_WORDS
  end

  def self.create_location_criteria(location_criteria)
    return { 'location' => 'me' } if location_criteria == 'me'
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
    criterion = criterion.select { |c| not approx_includes STEMMED_IGNORE_MODIFIERS, c }
    #STEMMED_SEARCH_MAPPINGS.select { |key, value| approx_includes [key.join(' ')], criterion.join(' ') }.map { |key, value| key }.first
    criterion.join ''
  end

  def self.parse_generic_criteria(criteria, list_of_things)
    pivot_index = criteria.length - (criteria.map { |word| approx_includes list_of_things, word }.reverse.index { |w| w } or criteria.length)
    criteria = criteria[pivot_index..-1]
    criteria = criteria.map { |w| w.split(//).last == ',' ? [w.split(//)[0..-2].join(''), ','] : w }.flatten
    criteria = criteria.chunk { |x| x == 'and' or x == ',' }.map { |x| x.last }.select { |x| x != ['and'] and x != [','] }
    filters = criteria.map { |criterion| criterion_to_querion criterion }
    if filters.empty?
      {}
    else
      {:filters => filters}
    end
  end

  def self.remove_non_spaceyalphanumeric(string)
    #string.gsub!(/[-.&]/, ' ')
    #string.split(//).select { |char| char =~ /[a-zA-Z0-9 ]/ }.join ''
    string.gsub!(/[-]/, ' ')
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

  def self.array_approx_includes(array1, array2)
    array1.map { |a| array2.inject (true) { |result, b| result and approx_includes(a, b) } }.inject (false) { |r, o| r or o }
  end

  def self.merge_array_to_hash(array)
    array.inject ({}) { |result, value| result.merge value }
  end

  def self.pivot_type(words)
    start_pivot, end_pivot = STEMMED_RESTAURANT_TYPES.map { |k, v| k }.map { |w| words.each_with_index.map { |word, i| approx_includes(STEMMED_RESTAURANT_TYPES.map { |k, v| k}, words[i..i+w.split(' ').length-1].join(' ')) ? [i, i+w.split(' ').length-1] : -1 } }.select { |x| not x.select { |y| y != -1 }.empty? }.first.select { |x| x != -1 }.first
    #pivot_index = words.map { |word| chunk_approx_includes(STEMMED_RESTAURANT_TYPES.map { |k, v| k }, word) }.index { |w| w }

    descriptions = words[0...start_pivot]
    type = STEMMED_RESTAURANT_TYPES[words[start_pivot..end_pivot].join ' ']
    criteria = remove_restaurant_words words[end_pivot+1..-1]

    [descriptions, type, criteria]
  end
  
  def self.remove_restaurant_words(words)
    return [] if words.empty?
    last_restaurant_word_index = (0...words.length).map { |n| array_approx_includes(STEMMED_RESTAURANT_WORDS, words[0..n]) ? n : -1 }.max
    words[last_restaurant_word_index+1..-1]
  end
end

class PlaceSearchApi < Sinatra::Base
  post '/search' do
    query = params[:query]
    results = PlaceSearch.search_wrapper(query)
    is_me = results['location']
    results.delete 'location'

    redirect "http://localhost:8888/yrs2012/?s=#{URI.encode(query)}&q=#{URI.encode(results.to_json)}&me=#{is_me}"
  end
  
  get '/search' do
    results = PlaceSearch.search_wrapper(params[:query])
    results.delete 'location'
    results.to_json
  end
end
