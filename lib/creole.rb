class Creole

  # Most of this code is ported from Jason Burnett's excellent Perl-based
  # converter which can be found here:
  # http://search.cpan.org/~jburnett/Text-WikiCreole/

  def self.strip_leading_and_trailing_eq_and_whitespace(s)
    s.sub!(/^\s*=*\s*/, '')
    s.sub!(/\s*=*\s*$/, '')
    return s
  end
	
  # strip list markup trickery
  def self.strip_list(s)
    
    # gemhack 4: It appears that this removes a space (or any number of ` chars)
    # prior to a * or # char and replaces them with a single `.  I'm not sure
    # that makes sense.  It seems that if there was no `, then one shouldn't be
    # added, and if there were multiple of them, then multiple should be added.
    # That said, Jason's a smart dude, so there may be more to this than meets
    # the eye.
    s.gsub!(/(?:`*| *)[\*\#]/, '`')
    
    # gemhack 4: I'm dubious about the need for this, however, I'm not totally
    # sure it's not needed, so I'm going to leave it in.  It seems like it
    # would serve the same function as the line above since it simply replaces
    # the contents after the \n with a `, much like the line above.
    s.gsub!(/\n(?:`*| *)[\*\#]/, "\n`")
    return s
  end
  
  # characters that may indicate inline wiki markup
  @@specialchars = ['^', '\\', '*', '/', '_', ',', '{', '[', 
                    '<', '~', '|', "\n", '#', ':', ';', '(', '-', '.']
                  
  # plain characters - auto-generated below (ascii printable minus @specialchars)
  @@plainchars = []

  # non-plain text inline widgets
  @@inline = %w{strong em br esc img link ilink inowiki
                sub sup mono u plug plug2 tm reg copy ndash ellipsis amp}
            
  @@all_inline = [@@inline, 'plain', 'any'].flatten # including plain text

  @@blocks = %w{h1 h2 h3 hr nowiki h4 h5 h6 ul ol table p ip dl plug plug2 blank}

end