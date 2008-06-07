require 'test/spec'
require 'texter/parser'
require 'set'

context 'RubyCodeParser' do
  class MockHandler
    attr_accessor :handled_strings

    def initialize
      @handled_strings = []
    end

    def string(n)
      @handled_strings << n
    end

    def ignore(n)
    end
  end

  class String
    def ruby_strings
      handler = MockHandler.new
      parser = RubyCodeParser.new
      parser.parse(self).process(handler)
      handler.handled_strings
    end
  end

  specify 'The parser should be able to extract strings' do
    code =<<-EOS
      aaa 'bbb' ccc("ddd", eee)
    EOS
    code.ruby_strings.map {|n|
      n.text_value
    }.to_set.should.equal %w['bbb' "ddd"].to_set
  end

  specify 'The parser should handle escaped single quotes correctly' do
    s = %q("foo\"bar\"")
    s.ruby_strings.map {|n| n.text_value}.should.equal [s]
  end

  specify 'The parser should handle escaped double quotes correctly' do
    s = %q('foo\'bar\'')
    s.ruby_strings.map {|n| n.text_value}.should.equal [s]
  end

  specify 'The parser should ignore quotes in comments' do
    code =<<-EOS
      # comment containing " and ' "
    EOS

    code.ruby_strings.should.be.empty
  end

  specify 'The parser should ignore quotes in regexp and % literals' do
    code =<<-EOS
      /'a"/ %r(a 'a') %Q{"foo"}
    EOS
    code.ruby_strings.should.be.empty
  end
end
