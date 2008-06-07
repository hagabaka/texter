#!/usr/bin/ruby
#
# texter is a utility to help you modify ruby source programs in order to use gettext.
# It searches for string literals, display each and ask you whether it should be
# marked as translatable, with _( ). In case the string contains embedded code, it
# is able to rewrite it with string modulo operator with your input
#
# USAGE
#   texter.rb <input-file> [<output-file>]
# output-file is by default <named input-file>.texter.rb
#
# AUTHOR
# Yaohan Chen <yaohan.chen@gmail.com>
#
# LICENSE
# Ruby's
#
# CREDITS
# - Daniel Brumbaugh Keeney provided much help with the treetop grammar and rest of
#   the program
#
# BUGS
# - The grammar treats ' and " inside regexp, here-doc, %( ) etc as string delimiters
# - Only strings enclosed in ' and " are handled
#
# TODO
# - Default answers for yes/no prompts
# - Preview
# (following probably too difficult)
# - Save and restore progress
# - Recover from incorrect parsing
# - Undo

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

