#!/usr/bin/env ruby

require 'test/unit'
require 'creole'

#puts Creole.creole_parse("; First title of definition list: Definition of first item.")

str2 = "; how 'bout  **__ Underlined bold __** in a definition list?
: not to mention, the actual // italicized definition //"

puts Creole.creole_parse(str2)

#words = "Before first colon: Before second colon: blah"
#PATT = /\G.*(?=:)/
#
#prev_last = 0
#last = 0
#while index = words.index(PATT, last)
#  puts index
#  puts $&
#  last = Regexp.last_match.end(0)
#  if last == prev_last
#    break
#  end
#  prev_last = last
#end

