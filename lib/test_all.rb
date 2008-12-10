#!/usr/bin/env ruby

require 'test/unit'
require 'Creole'

class TC_Creole < Test::Unit::TestCase
  
  #-----------------------------------------------------------------------------
  # This first section is the low level method sanity tests.

  def test_strip_leading_and_trailing_eq_and_whitespace
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("==head")
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace(" == head")
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("head ==")
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("head == ")
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("head  ")
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("  head")
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("  head  ")
  end
  
  def test_strip_list
    assert_equal "`head", Creole.strip_list(" *head")
    assert_equal "\n`head", Creole.strip_list("\n *head")
    assert_equal "`**head", Creole.strip_list("***head")
  end
  
  def test_chunk_filter_lambdas
    assert_equal "a string with a  in it", Creole.filter_string_x_with_chunk_filter_y("a string with a : in it", :ip)
    assert_equal "a string with a newline", Creole.filter_string_x_with_chunk_filter_y("a string with a newline\n", :p)
    assert_equal "a string with a newline", Creole.filter_string_x_with_chunk_filter_y("a string with a newline\n", :dd)
    assert_equal "", Creole.filter_string_x_with_chunk_filter_y("a non-blank string", :blank)
    
    #special... uses strip_list function inside the lamda function
    assert_equal "`head", Creole.filter_string_x_with_chunk_filter_y(" *head", :ul)
    assert_equal "head", Creole.filter_string_x_with_chunk_filter_y("head == ", :h5)
  end
  
  def test_init
    Creole.init
    assert_equal 1, 1
  end
  
  def test_sub_chunk_for
    Creole.init
    str = "//Hello// **Hello**"
    assert_equal :p, Creole.get_sub_chunk_for(str, :top, 0)
    assert_equal :em, Creole.get_sub_chunk_for(str, :p, 0)
    assert_equal :plain, Creole.get_sub_chunk_for(str, :p, 9)
    assert_equal :strong, Creole.get_sub_chunk_for(str, :p, 10)
  end
  
  def test_strong
    s = Creole.creole_parse("**Hello**")
    assert_equal "<p><strong>Hello</strong></p>\n\n", s
  end
  
  def test_italic
    s = Creole.creole_parse("//Hello//")
    assert_equal "<p><em>Hello</em></p>\n\n", s
  end
  
  def test_italic_bold_with_no_spaces
    s = Creole.creole_parse("//Hello//**Hello**")
    assert_equal "<p><em>Hello</em><strong>Hello</strong></p>\n\n", s
  end
  
  def test_italic_bold_with_a_space_in_the_middle
    s = Creole.creole_parse("//Hello// **Hello**")
    assert_equal "<p><em>Hello</em> <strong>Hello</strong></p>\n\n", s
  end
  
  def test_two_paragraph_italic_bold_with_a_space_in_the_middle
    s = Creole.creole_parse("//Hello// **Hello**\n\n//Hello// **Hello**")
    assert_equal "<p><em>Hello</em> <strong>Hello</strong></p>\n\n<p>" +
      "<em>Hello</em> <strong>Hello</strong></p>\n\n", s
  end
  
  def test_link_with_a_page_name
    s = Creole.creole_parse("the site http://www.yahoo.com/page.html is a site")
    assert_equal %Q{<p>the site <a href="http://www.yahoo.com/page.html">http://www.yahoo.com/page.html</a> is a site</p>\n\n}, s
  end
  
  def test_link_with_a_trailing_slash
    # This test caught a bug in the initial parser, so I changed the ilink
    # :stops regex so it worked.
    s = Creole.creole_parse("the site http://www.yahoo.com/ is a site")
    assert_equal %Q{<p>the site <a href="http://www.yahoo.com/">http://www.yahoo.com/</a> is a site</p>\n\n}, s
  end
  
  def test_escaped_url
    # This behavior is wrong.  If you move the tilda to the
    # beginning of the http, where it makes more sense, it breaks.  Without
    # negative lookback assertions it may be the best we can do without
    # significanly hampering performance.
    s = Creole.creole_parse("the site http:~//www.yahoo.com/ is a site")
    assert_equal %Q{<p>the site http://www.yahoo.com/ is a site</p>\n\n}, s
  end
  
  #-----------------------------------------------------------------------------
  # Test the links
  
  def test_link_with_text
    markup = "This is a paragraph with a [[ link | some link ]].\nCheck it out."
    goodhtml = %Q{<p>This is a paragraph with a <a href="link">some link</a>.\nCheck it out.</p>\n\n}
    
    assert_equal goodhtml, Creole.creole_parse(markup)
    
  end
  
  def test_link_with_no_text
    markup = "This is a paragraph with a [[ link ]].\nCheck it out."
    goodhtml = %Q{<p>This is a paragraph with a <a href="link">link</a>.\nCheck it out.</p>\n\n}
    
    assert_equal goodhtml, Creole.creole_parse(markup)
    
  end
  
  def test_user_supplied_creole_link_function
    
    uppercase = Proc.new {|s| 
      s.upcase!
      s
    }
    Creole.creole_link(uppercase)
    
    markup = "This is a paragraph with an uppercased [[ link ]].\nCheck it out."
    goodhtml = %Q{<p>This is a paragraph with an uppercased <a href="LINK">link</a>.\nCheck it out.</p>\n\n}
    
    assert_equal goodhtml, Creole.creole_parse(markup)
    
    # set the link function back to being nil so that the rest of the tests
    # are not affected by the custom link function
    Creole.creole_link(nil)

  end
  
  def test_puts_existing_creole_tags
    tags = Creole.creole_tag("suppress_puts")
    assert tags.index(/u: open\(<u>\) close\(<\/u>\)/)
  end
  
  def test_custom_creole_tag
    Creole.creole_tag(:p, :open, "<p class=special>")

    markup = "This is a paragraph."
    goodhtml = "<p class=special>This is a paragraph.</p>\n\n"

    assert_equal goodhtml, Creole.creole_parse(markup)
    Creole.creole_tag(:p, :open, "<p>")
  end
  
  def test_user_supplied_plugin_function
    uppercase = Proc.new {|s| 
      s.upcase!
      s
    }
    Creole.creole_plugin(uppercase)
    
    markup = "This is a paragraph with an uppercasing << plugin >>.\nCheck it out."
    goodhtml = %Q{<p>This is a paragraph with an uppercasing  PLUGIN .\nCheck it out.</p>\n\n}
    
    assert_equal goodhtml, Creole.creole_parse(markup)
    
    # set the link function back to being nil so that the rest of the tests
    # are not affected by the custom link function
    Creole.creole_plugin(nil)
  end

  #-----------------------------------------------------------------------------
  # Below here are all the file based tests.  They read the .markup file,
  # parse it, then validate that it matches the pre-existing .html file.
  
  def test_amp
    run_testfile("amp")
  end
  
  def test_block
    run_testfile("block")
  end
  
  def test_escape
    run_testfile("escape")
  end
  
  def test_inline
    run_testfile("inline")
  end
  
  def test_specialchars
    run_testfile("specialchars")
  end
  
  def test_jsp_wiki
    # This test was found on the Creole website.  I had to hand-tweak it a bit
    # for it to make sense for our paticular settings, however, the fundamentals
    # are the same as they were in the original test.
    run_testfile("jsp_wiki")    
  end
  
  def run_testfile(name)
    name = "test_" + name
    markup = File.read("./#{name}.markup")
    html = File.read("./#{name}.html")
    parsed = Creole.creole_parse(markup)
    #write_file("./#{name}.processed", parsed) if name.index(/jsp/)
    assert_equal html, parsed
  end
  
  def write_file(filename, data)
    f = File.new(filename, "w")
    f.write(data)
    f.close
  end

end
