require 'fast_stemmer'
require 'text'
require 'sinatra/base'
require 'json'

# See http://www.ruby-forum.com/topic/59614
class Regexp
  def +(re)
    Regexp.new self.to_s + re.to_s
  end
end

class PlaceSearch
  RESTAURANT_TYPES = %w{italian mexican chinese}
  RESTAURANT_WORDS = %w{restaurant place}
  LOCATION_WORDS = %w{near located}
  START_STOP_WORDS = %w{find search me a an one some few}
  STOP_STOP_WORDS = %w{that is also}

  LEV_LENGTH_COEFFICIENT = 1/4

  SEARCH_MAPPINGS = {
    "healthy" => {:health_score => {"$gt" => 3}},
    "cheap" => {:cheap => true}
  }

  STEMMED_START_STOP_WORDS = START_STOP_WORDS.map { |word| word.stem }
  STEMMED_STOP_STOP_WORDS = STOP_STOP_WORDS.map { |word| word.stem }
  STEMMED_RESTAURANT_TYPES = RESTAURANT_TYPES.map { |word| word.stem }
  STEMMED_RESTAURANT_WORDS = RESTAURANT_WORDS.map { |word| word.stem }
  STEMMED_LOCATION_WORDS = LOCATION_WORDS.map { |word| word.stem }
  STEMMED_SEARCH_MAPPINGS = Hash[SEARCH_MAPPINGS.map { |key, value| [key.stem, value] }]

  def self.search(string)
    words = pre_parse(string)
    pre_criteria, type, criteria = pivot_type words
    pre_criteria = parse_pre_criteria pre_criteria
    criteria = parse_criteria criteria


    [pre_criteria, type, criteria]
  end

  protected
  def self.parse_criteria(criteria)
    pivot_index = criteria.length - criteria.map { |word| approx_includes STEMMED_STOP_STOP_WORDS, word }.reverse.index { |w| w }
    criteria = criteria[pivot_index..-1].map { |w| w.split(//).last == ',' ? [w.split(//)[0..-2].join(''), ','] : w }.flatten
    criteria.chunk { |x| x == 'and' or x == ',' }.map { |x| x.last }.select { |x| x != ['and'] and x != [','] }
  end

  def self.parse_pre_criteria(criteria)
    pivot_index = criteria.length - criteria.map { |word| approx_includes STEMMED_START_STOP_WORDS, word }.reverse.index { |w| w }
    criteria = criteria[pivot_index..-1].map { |w| w.split(//).last == ',' ? [w.split(//)[0..-2].join(''), ','] : w }.flatten
    criteria.chunk { |x| x == 'and' or x == ',' }.map { |x| x.last }.select { |x| x != ['and'] and x != [','] }
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
  get '/search.json' do
    content_type :json

    PlaceSearch.search(params[:query]).to_json
  end
end


  #def self.search(string)
    #words = pre_parse(string)
    #words = remove_stop_words words
    #descriptions, type, criteria = pivot_type words

    #query = {
      #:type => type
    #}

    #query.merge! make_query_from_description descriptions
    #query.merge! make_query_from_criteria criteria

    #query
  #end



  #def self.make_query_from_description(description)
    #merge_array_to_hash description.map { |desc| STEMMED_SEARCH_MAPPINGS[desc] }.select { |desc| not desc.nil? }
  #end

  #def self.make_query_from_location_criteria(location_criteria)
    #{:location => location_criteria}
  #end

  #def self.make_query_from_criterion(criterion)
    #criterion = criterion.split ' '
    #if approx_includes STEMMED_LOCATION_WORDS, criterion.first
      #location_criteria = criterion[1..-1]
      
      #make_query_from_location_criteria location_criteria
    #else
      #make_query_from_description criterion
    #end
  #end

  #def self.make_query_from_criteria(criteria)
    #merge_array_to_hash criteria.join(' ').split(' and').map { |criterion| make_query_from_criterion criterion }
  #end
#end

#class PlaceSearchApi < Sinatra::Base
  #get '/search.json' do
    #content_type :json

    #PlaceSearch.search(params[:query]).to_json
  #end
#end
