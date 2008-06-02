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

require 'treetop'
require 'highline'

Treetop.load_from_string <<'END_GRAMMAR'

grammar RubyCode
  rule code
    (ignored / string / braced_code)* <CodeNode>
  end

  # this rule is to guarantee that { } always occur in matched pairs in code
  # it is necessary as } is used to terminate interpolated code in strings
  rule braced_code
    '{' code '}' <BracedCodeNode>
  end

  rule ignored
    (comment / !quote ![{}] .) <IgnoredNode>
  end

  rule comment
    '#' (!linebreak .)* (linebreak / !.)
  end

  rule string
    (double_string / single_string) <StringNode>

  end

  rule double_string
    double_quote body:(interpolated_code / double_string_body)* double_quote
    <DoubleStringNode>
  end

  rule single_string
    single_quote (!single_quote .)* single_quote <SingleStringNode>
  end

  rule double_string_body
    !double_quote . <DoubleStringBodyNode>
  end

  rule interpolated_code
    ( '#{' body:code '}' /
      '#' body:([$@] [a-zA-Z0-9_]+) ) <InterpolatedCodeNode>
  end

  rule quote
    double_quote / single_quote
  end

  rule double_quote
    '"'
  end

  rule single_quote
    "'"
  end

  rule linebreak
    "\r\n" / "\n" / "\r"
  end
end

END_GRAMMAR

class CodeNode < Treetop::Runtime::SyntaxNode
  def process
    elements.each {|e| e.process}
  end
end

class BracedCodeNode < Treetop::Runtime::SyntaxNode
  def process
    OUTPUT.write('{')
    code.process
    OUTPUT.write('}')
  end
end

module IgnoredNode
  def process
    OUTPUT.write(text_value)
  end
end

module StringNode
  LINE_BOUNDARY = /\n|\r\n|\r|\A|\Z/
  def process
    # when a string is found, we print the surrounding text and highlight the string
    context_start = interval.first
    context_end = interval.last
    # try to find two lines before the start of string, and after end of string
    2.times do
      try_start = INPUT.rindex(LINE_BOUNDARY, [context_start-1, 0].max)
      try_end = INPUT.index(LINE_BOUNDARY, [context_end+1, INPUT.length-1].min)
      context_start, context_end = try_start || context_start, try_end || context_end
    end

    HIGHLINE.say "String literal found at #{interval.inspect}:\n#{
      INPUT[context_start...interval.first] +
      HIGHLINE.color(text_value, :bold) +
      INPUT[interval.last..context_end]
    }"

    if HIGHLINE.agree('Mark this string translatable? ') {|q| q.default = 'n'}
      mark_translatable
    else
      OUTPUT.write text_value
    end
  end
end

class DoubleStringNode < Treetop::Runtime::SyntaxNode
  LABEL_FORMAT = /[A-Za-z_]+/
    def mark_translatable
      string = ''
      labels = {}
      body.elements.each do |e|
        if e.code?
          body = e.body.text_value
          label = HIGHLINE.ask("Specify label for embedded code #{
            HIGHLINE.color(body, :bold)}: ") {|q|
            q.validate = proc {|l| !labels.include?(l) && l =~ LABEL_FORMAT}
            default = body[LABEL_FORMAT]
            default += '_' while default.empty? || labels.include?(default)
            q.default = default
          }
          labels[label] = body
          string += "%{#{label}}"
        else
          string += e.text_value
        end
      end

      result = %Q[_("#{string}")]
      unless labels.empty?
        result += " % {#{ labels.map {|(k, v)| ":#{k} => #{v}"}.join(', ') }}"
        result = "(#{result})" if
        HIGHLINE.agree "Does #{result} need to be parenthesized? "
      end
      OUTPUT.write result
    end
end

class SingleStringNode < Treetop::Runtime::SyntaxNode
  def mark_translatable
    OUTPUT.write "_(#{text_value})"
  end
end

class DoubleStringBodyNode < Treetop::Runtime::SyntaxNode
  def code?
    false
  end
end

module InterpolatedCodeNode
  def code?
    true
  end
end


HIGHLINE = HighLine.new

inpath =  ARGV[0] or
begin
  HIGHLINE.say 'Usage: texter.rb <inputfile> [<outputfile>]'
  exit
end

outpath = ARGV[1] || "#{inpath}.texter.rb"

parser = RubyCodeParser.new
File.open(outpath, 'w') do |f|
  OUTPUT = f
  INPUT = File.read(inpath)
  parser.parse(INPUT).process
end

