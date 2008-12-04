#!/usr/bin/env ruby

require 'test/unit'
require 'Creole'

class TC_Creole < Test::Unit::TestCase

  def test_strip_leading_and_trailing_eq_and_whitespace
    assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("==head")
	assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace(" == head")
	assert_equal "head", Creole.strip_leading_and_trailing_eq_and_whitespace("head ===")
  end
  
  def test_strip_list
    #assert_equal "`head", Creole.strip_leading_and_trailing_eq_and_whitespace(" **head")
  end
  
end
