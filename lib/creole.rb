class Creole

	# Most of this code is based off of Jason Burnett's excellent Perl-based converter which can be found here:
	# http://search.cpan.org/~jburnett/Text-WikiCreole/

	def self.strip_leading_and_trailing_eq_and_whitespace(s)
	  s.sub!(/^\s*=*\s*/, '')
	  s.sub!(/\s*=*\s*$/, '')
	end

	# strip list markup trickery
	def self.strip_list(s)
	  s.gsub!(/(?:`*| *)[\*\#]/, '`')
	  s.gsub!(/\n(?:`*| *)[\*\#]/, "\n`")
	end

end