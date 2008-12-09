require 'test/unit'
require 'creole'

class TC_CreoleInline < Test::Unit::TestCase
  
  def test_escape
    name = "test_escape"
    markup = File.read("./#{name}.markup")
    html = File.read("./#{name}.html")
    
    parsed = Creole.creole_parse(markup)
    
    #write_file("./#{name}.parsed", parsed)
    assert_equal html, parsed
  end
  
  def write_file(filename, data)
    f = File.new(filename, "w")
    f.write(data)
    f.close
  end
  
end
