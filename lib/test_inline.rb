require 'test/unit'
require 'Creole'

class TC_CreoleInline < Test::Unit::TestCase
  
  def test_inline
    name = "test_inline"
    markup = File.read("./#{name}.markup")
    html = File.read("./#{name}.html")
    
    parsed = Creole.creole_parse(markup)
    
    #write_parsed_output("./#{name}.parsed", parsed)
    assert_equal html, parsed
  end
  
  def write_parsed_output(file, data)
    f = File.new("./inline.parsed", "w")
    f.write(data)
    f.close
  end
  
end
