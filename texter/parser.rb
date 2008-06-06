require 'treetop'

Treetop.load_from_string <<'END_GRAMMAR'

grammar RubyCode
  rule code
    (ignored / string / braced_code)* <CodeNode>
  end

  # this rule is to guarantee that { } always occur in matched pairs in code
  # it is necessary as } is used to terminate interpolated code in strings
  rule braced_code
    open_brace:'{' code close_brace:'}' <BracedCodeNode>
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
    open_quote:double_quote
    body:(interpolated_code / double_string_body)*
    close_quote:double_quote
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
  def process(h)
    elements.each {|e| e.process(h)}
  end
end

class BracedCodeNode < Treetop::Runtime::SyntaxNode
  def process(h)
    h.ignore open_brace
    code.process(h)
    h.ignore close_brace
  end
end

module IgnoredNode
  def process(h)
    h.ignore self
  end
end

module StringNode
  def process(h)
    h.string self
 end
end

class DoubleStringNode < Treetop::Runtime::SyntaxNode
  def single_quoted?
    false
  end

  def double_quoted?
    true
  end
end

class SingleStringNode < Treetop::Runtime::SyntaxNode
  def single_quoted?
    true
  end

  def double_quoted?
    false
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

