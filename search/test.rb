require_relative 'search'
require 'open-uri'
require 'colored'

open('test_data').read.split("\n")[1..-1].map { |l| l.split('|')[1..-1].map { |v| v.strip.lstrip } }.each do |row|
  wanted = {
    :type => row[1],
    :filters => [row[2]],
    :location => row[3]
  }
  wanted = Hash[wanted.select { |k, v| not (v.empty? or v == [""]) }]

  actual = PlaceSearch.search row[0]

  if actual == wanted
    puts "Successful: #{row[0]} - #{wanted}".green
  else
    puts "Failed: #{row[1]}".red
    puts "Expected: #{wanted}".red
    puts "Actual: #{actual}".red
  end
end

puts PlaceSearch.search_wrapper 'Healthy Italian near Brighton Station'
puts PlaceSearch.search_wrapper ''
