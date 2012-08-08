require 'fast_stemmer'
require 'text'

# See http://www.ruby-forum.com/topic/59614
class Regexp
  def +(re)
    Regexp.new self.to_s + re.to_s
  end
end

STOP_WORDS = %w{hey hi please thanks thank you can find search me an one a some for}
STEMMED_STOP_WORDS = STOP_WORDS.map { |word| word.stem }
RESTAURANT_TYPES = %w{italian}
STEMMED_RESTAURANT_TYPES = RESTAURANT_TYPES.map { |word| word.stem }
RESTAURANT_WORDS = %w{restaurant place}
STEMMED_RESTAURANT_WORDS = RESTAURANT_WORDS.map { |word| word.stem }
LOCATION_WORDS = %w{near}
STEMMED_LOCATION_WORDS = LOCATION_WORDS.map { |word| word.stem }

SEARCH_MAPPINGS = {
  "healthy" => {:health_score => {"$gt" => 3}},
  "cheap" => {:cheap => true}
}
STEMMED_SEARCH_MAPPINGS = Hash[SEARCH_MAPPINGS.map { |key, value| [key.stem, value] }]

def remove_non_spaceyalphanumeric(string)
  string.split(//).select { |char| char =~ /[a-zA-Z0-9 ]/ }.join ''
end

def stem_words(string)
  string.split(' ').map { |word| word.stem }
end

def pre_parse(string)
  string = remove_non_spaceyalphanumeric string
  string.downcase!
  stem_words string
end

def remove_stop_words(words)
  words.select { |word| not STEMMED_STOP_WORDS.include? word }
end

def remove_restaurant_words(words)
  if (STEMMED_RESTAURANT_WORDS + RESTAURANT_WORDS).map { |rest_word| Text::Levenshtein.distance words.first, rest_word }.min <= 3
    words[1..-1]
  else
    words
  end
end

def pivot_type(words)
  word_bools = words.map { |word| STEMMED_RESTAURANT_TYPES.include? word }
  pivot_index = word_bools.index { |w| w }

  descriptions = words[0...pivot_index]
  type = words[pivot_index]
  criteria = remove_restaurant_words words[pivot_index+1..-1]

  [descriptions, type, criteria]
end

def merge_array_to_hash(array)
  array.inject ({}) { |result, value| result.merge value }
end

def make_query_from_description(description)
  merge_array_to_hash description.map { |desc| STEMMED_SEARCH_MAPPINGS[desc] }.select { |desc| not desc.nil? }
end

def make_query_from_location_criteria(location_criteria)
  {:location => location_criteria}
end

def make_query_from_criterion(criterion)
  criterion = criterion.split ' '
  if STEMMED_LOCATION_WORDS.include? criterion.first
    location_criteria = criterion[1..-1]
    
    make_query_from_location_criteria location_criteria
  else
    make_query_from_description criterion
  end
end

def make_query_from_criteria(criteria)
  merge_array_to_hash criteria.join(' ').split(' and').map { |criterion| make_query_from_criterion criterion }
end

def search(string)
  words = pre_parse(string)
  words = remove_stop_words words
  descriptions, type, criteria = pivot_type words

  query = {
    :type => type
  }

  query.merge! make_query_from_description descriptions
  query.merge! make_query_from_criteria criteria

  query
end

puts search(ARGV.first).inspect
