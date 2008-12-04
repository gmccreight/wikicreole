class Creole

	# Most of this code is based off of Jason Burnett's excellent Perl-based converter which can be found here:
	# http://search.cpan.org/~jburnett/Text-WikiCreole/
	
	@compiled_strip_eq_1 = Regexp.compile(/^\s*=*\s*/)
	@compiled_strip_eq_2 = Regexp.compile(/\s*=*\s*$/)

	def self.strip_leading_and_trailing_eq_and_whitespace(s)
	  s.sub!(@compiled_strip_eq_1, '')
	  s.sub!(@compiled_strip_eq_2, '')
	end

	# @compiled_list_strip_1 = Regexp.compile(/(?:`*| *)[\*\#]/)
	# @compiled_list_strip_2 = Regexp.compile(/\n(?:`*| *)[\*\#]/)
	
	# # strip list markup trickery
	# def self.strip_list(s)
	  # s.gsub!(@compiled_list_strip_1, '`')
	  # s.gsub!(@compiled_list_strip_2, "\n`")
	# end

end