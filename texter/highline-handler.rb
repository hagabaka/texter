require 'highline'

class HighLineHandler
  LINE_BOUNDARY = /\n|\r\n|\r|\A|\Z/

  def initialize(input, output)
    @input = input
    @output = output
    @highline = HighLine.new
  end

  def ignore(n)
    @output.write(n.text_value)
  end

  def string(n)
    # when a string is found, we print the surrounding text and highlight the string
    context_start = n.interval.first
    context_end = n.interval.last
    # try to find two lines before the start of string, and after end of string
    2.times do
      try_start = @input.rindex(LINE_BOUNDARY, [context_start-1, 0].max)
      try_end = @input.index(LINE_BOUNDARY, [context_end+1, @input.length-1].min)
      context_start, context_end = try_start || context_start, try_end || context_end
    end

    @highline.say "String literal found at #{n.interval.inspect}:\n#{
      @input[context_start...n.interval.first] +
      @highline.color(n.text_value, :bold) +
      @input[n.interval.last..context_end]
    }"

      if @highline.agree('Mark this string translatable? ') {|q| q.default = 'n'}
        mark_translatable(n)
      else
        ignore(n)
      end
  end

  LABEL_FORMAT = /[A-Za-z_]+/
  def mark_translatable(n)
    if n.single_quoted?
      @output.write "_(#{n.text_value})"
    else
      string = ''
      labels = {}
      n.body.elements.each do |e|
        if e.code?
          code = e.body.text_value
          label = @highline.ask("Specify label for embedded code #{
            @highline.color(code, :bold)
          }: ") do |q|
            q.validate = proc {|l| !labels.include?(l) && l =~ LABEL_FORMAT}
            default = code[LABEL_FORMAT]
            default += '_' while default.empty? || labels.include?(default)
            q.default = default
          end
          labels[label] = code
          string += "%{#{label}}"
        else
          string += e.text_value
        end
      end

      result = "_(#{n.open_quote.text_value}#{string}#{n.close_quote.text_value})"
      unless labels.empty?
        result += " % {#{ labels.map {|(k, v)| ":#{k} => #{v}"}.join(', ') }}"
        result = "(#{result})" if @highline.agree("Parenthesize the expression #{
          @highline.color(result, :bold)}? ") {|q| q.default = 'y'}
      end
      @output.write result
    end
  end
end
