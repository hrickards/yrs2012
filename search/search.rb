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
  IGNORE_MODIFIERS = %w{very relatively quite really}

  LEV_LENGTH_COEFFICIENT = 1/4

  SEARCH_MAPPINGS = {
    %w{healthy} => {:rating_value => {"$gt" => 3}},
    %w{cheap} => {:cheap => true},
    %w{nut free} => {:nut_free => true}
  }

  STEMMED_START_STOP_WORDS = START_STOP_WORDS.map { |word| word.stem }
  STEMMED_STOP_STOP_WORDS = STOP_STOP_WORDS.map { |word| word.stem }
  STEMMED_RESTAURANT_TYPES = RESTAURANT_TYPES.map { |word| word.stem }
  STEMMED_RESTAURANT_WORDS = RESTAURANT_WORDS.map { |word| word.stem }
  STEMMED_LOCATION_WORDS = LOCATION_WORDS.map { |word| word.stem }
  STEMMED_SEARCH_MAPPINGS = Hash[SEARCH_MAPPINGS.map { |key, value| [key.map { |w| w.stem }, value] }]

  def self.search(string)
    words = pre_parse(string)
    pre_criteria, type, criteria = pivot_type words

    query = { :type => type }

    query.merge! parse_pre_criteria(pre_criteria)

    pre_criteria = parse_pre_criteria pre_criteria
    #criteria = parse_criteria criteria
   
    query
  end

  protected
  def self.parse_criteria(criteria)
    parse_generic_criteria STEMMED_STOP_STOP_WORDS, criteria
  end

  def self.parse_pre_criteria(criteria)
    parse_generic_criteria STEMMED_START_STOP_WORDS, criteria
  end

  def self.criterion_to_querion(criterion)
    STEMMED_SEARCH_MAPPINGS.select { |key, value| approx_includes [key.join(' ')], criterion.join(' ') }.map { |key, value| value }.first
  end

  def self.parse_generic_criteria(list_of_stuff, criteria)
    pivot_index = criteria.length - criteria.map { |word| approx_includes list_of_stuff, word }.reverse.index { |w| w }
    criteria = criteria[pivot_index..-1].map { |w| w.split(//).last == ',' ? [w.split(//)[0..-2].join(''), ','] : w }.flatten
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
