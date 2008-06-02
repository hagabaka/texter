require 'treetop'

Treetop.load_from_string <<'END_GRAMMAR'

grammar RubyCode
  rule code
    (ignored / string / braced_code)* {
      def process(output_file)
        elements.each {|e| e.process(output_file)}
      end
    }
  end

  rule braced_code
    '{' code '}' {
      def process(output_file)
        output_file.write('{')
        code.process(output_file)
        output_file.write('}')
      end
    }
  end

  rule ignored
    (comment / !quote ![{}] .) {
      def process(output_file)
        output_file.write(text_value)
      end
    }
  end

  rule comment
    '#' (!linebreak .)* (linebreak / !.)
  end

  rule string
    ( double_quote body:(interpolated_code / double_string_body)* double_quote /
      single_quote body:single_string_body* single_quote ) {
      def process(output_file)
        puts "STRING: #{text_value}"
        output_file.puts "******#{text_value}*******"
        body.elements.each do |e|
          e.process(output_file)
        end
      end
    }
  end

  rule double_string_body
    !double_quote . {
      def process(output_file)
        # output_file.write text_value
      end
    }
  end

  rule single_string_body
    !single_quote . {
      def process(output_file)
        # output_file.write text_value
      end
    }
  end


  rule interpolated_code
    ( '#{' body:code '}' /
      '#' body:([$@] [a-zA-Z0-9_]+) ) {
      def process(output_file) 
        puts "CODE: #{body.text_value}"
      end
    }
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

infile =  ARGV[0] 
outfile = ARGV[1] || "#{infile}.texter.rb"

parser = RubyCodeParser.new
File.open(outfile, 'w') do |f|
  parser.parse(File.read(infile)).process(f)
end
