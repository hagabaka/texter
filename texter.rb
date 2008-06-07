#!/usr/bin/ruby

require 'texter/highline-handler.rb'
require 'texter/parser.rb'
 
inpath =  ARGV[0] or
begin
  puts 'Usage: texter.rb <inputfile> [<outputfile>]'
  exit
end

outpath = ARGV[1] || "#{inpath}.texter.rb"

parser = RubyCodeParser.new
input = File.read(inpath)
File.open(outpath, 'w') do |output|
  handler = HighLineHandler.new(input, output)
  parser.parse(input).process(handler)
end

