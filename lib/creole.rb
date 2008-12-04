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
  
  @is_initialized = false

  @@chunks_hash = {
    :top => {
       :contains => @@blocks,
    },
    :blank => {
      :curpat => "(?= *$eol)",
      :fwpat => "(?=(?:^|\n) *$eol)",
      :stops => '(?=\S)',
      :hint => ["\n"],
      :filter => Proc.new { "" }, # whitespace into the bit bucket
      :open => "", :close => "",
    },
    :p => {
      :curpat => '(?=.)',
      :stops => ['blank', 'ip', 'h', 'hr', 'nowiki', 'ul', 'ol', 'dl', 'table'],
      :hint => @@plainchars,
      :contains => @@all_inline,
      :filter => Proc.new {|s| s.chomp },
      :open => "<p>", :close => "</p>\n\n",
    },
    :ip => {
      :curpat => '(?=:)',
      :fwpat => '\n(?=:)',
      :stops => ['blank', 'h', 'hr', 'nowiki', 'ul', 'ol', 'dl', 'table'],
      :hint => [':'],
      :contains => ['p', 'ip'],
      :filter => Proc.new {|s|
        s.sub!(/:/, '')
        s.sub!(/\n:/, "\n")
        s
      },
      :open => "<div style=\"margin-left: 2em\">", :close => "</div>\n",
    }
#    :dl => {
#      :curpat => '(?=;)',
#      :fwpat => '\n(?=;)',
#      :stops => ['blank', 'h', 'hr', 'nowiki', 'ul', 'ol', 'table'],
#      :hint => [';'],
#      :contains => ['dt', 'dd'],
#      :open => "<dl>\n", :close => "</dl>\n",
#    },
#    :dt => {
#      :curpat => '(?=;)',
#      :fwpat => '\n(?=;)',
#      :stops => '(?=:|\n)',
#      :hint => [';'],
#      :contains => @@all_inline,
#      :filter => sub { $_[0] =~ s/^;\s*//o; return $_[0]; },
#      :open => "  <dt>", :close => "</dt>\n",
#    },
#    :dd => {
#      :curpat => '(?=\n|:)',
#      :fwpat => '(?:\n|:)',
#      :stops => '(?=:)|\n(?=;)',
#      :hint => [':', "\n"],
#      :contains => @@all_inline,
#      :filter => sub { 
#        $_[0] =~ s/(?:\n|:)\s*//so; 
#        $_[0] =~ s/\s*$//so;
#        return $_[0]; 
#      },
#      :open => "    <dd>", :close => "</dd>\n",
#    },
#    :table => {
#      :curpat => '(?= *\|.)',
#      :fwpat => '\n(?= *\|.)',
#      :stops => '\n(?= *[^\|])',
#      :contains => ['tr'],
#      :hint => ['|', ' '],
#      :open => "<table>\n", :close => "</table>\n\n",
#    },
#    :tr => {
#      :curpat => '(?= *\|)',
#      :stops => '\n',
#      :contains => ['td', 'th'],
#      :hint => ['|', ' '],
#      :filter => sub { $_[0] =~ s/^ *//o; $_[0] =~ s/\| *$//o; return $_[0]; },
#      :open => "    <tr>\n", :close => "    </tr>\n",
#    },
#    :td => {
#      :curpat => '(?=\|[^=])',
#      # this gnarly regex fixes ambiguous '|' for links/imgs/nowiki in tables
#      :stops => '[^~](?=\|(?!(?:[^\[]*\]\])|(?:[^\{]*\}\})))',
#      :contains => @@all_inline,
#      :hint => ['|'],
#      :filter => sub {$_[0] =~ s/^ *\| *//o; $_[0] =~ s/\s*$//so; return $_[0]; },
#      :open => "        <td>", :close => "</td>\n",
#    },
#    :th => {
#      :curpat => '(?=\|=)',
#      # this gnarly regex fixes ambiguous '|' for links/imgs/nowiki in tables
#      :stops => '[^~](?=\|(?!(?:[^\[]*\]\])|(?:[^\{]*\}\})))',
#      :contains => @@all_inline,
#      :hint => ['|'],
#      :filter => sub {$_[0] =~ s/^ *\|= *//o; $_[0] =~ s/\s*$//so; return $_[0]; },
#      :open => "        <th>", :close => "</th>\n",
#    },
#    :ul => {
#      :curpat => '(?=(?:`| *)\*[^\*])',
#      :fwpat => '(?=\n(?:`| *)\*[^\*])',
#      :stops => ['blank', 'ip', 'h', 'nowiki', 'li', 'table', 'hr', 'dl'],
#      :contains => ['ul', 'ol', 'li'],
#      :hint => ['*', ' '],
#      :filter => \&strip_list,
#      :open => "<ul>\n", :close => "</ul>\n",
#    },
#    :ol => {
#      :curpat => '(?=(?:`| *)\#[^\#])',
#      :fwpat => '(?=\n(?:`| *)\#[^\#])',
#      :stops => ['blank', 'ip', 'h', 'nowiki', 'li', 'table', 'hr', 'dl'],
#      :contains => ['ul', 'ol', 'li'],
#      :hint => ['#', ' '],
#      :filter => \&strip_list,
#      :open => "<ol>\n", :close => "</ol>\n",
#    },
#    :li => {
#      :curpat => '(?=`[^\*\#])',
#      :fwpat => '\n(?=`[^\*\#])',
#      :stops => '\n(?=`)',
#      :hint => ['`'],
#      :filter => sub { 
#        $_[0] =~ s/` *//o;
#        chomp $_[0];
#        return $_[0];
#      },
#      :contains => @@all_inline,
#      :open => "    <li>", :close => "</li>\n",
#    },
#    :nowiki => {
#      :curpat => '(?=\{\{\{ *\n)',
#      :fwpat => '\n(?=\{\{\{ *\n)',
#      :stops => "\n\}\}\} *$eol",
#      :hint => ['{'],
#      :filter => sub {
#        substr($_[0], 0, 3, '');
#        $_[0] =~ s/\}\}\}\s*$//o;
#        $_[0] =~ s/&/&amp;/go;
#        $_[0] =~ s/</&lt;/go;
#        $_[0] =~ s/>/&gt;/go;
#        return $_[0];
#      },
#      :open => "<pre>", :close => "</pre>\n\n",
#    },
#    :hr => {
#      :curpat => "(?= *-{4,} *$eol)",
#      :fwpat => "\n(?= *-{4,} *$eol)",
#      :hint => ['-', ' '],
#      :stops => $eol,
#      :open => "<hr />\n\n", :close => "",
#      :filter => sub { return ""; } # ----- into the bit bucket
#    },
#    :h => { :curpat => '(?=(?:^|\n) *=)' }, # matches any heading
#    :h1 => {
#      :curpat => '(?= *=[^=])',
#      :hint => ['=', ' '], 
#      :stops => '\n',
#      :contains => @@all_inline,
#      :open => "<h1>", :close => "</h1>\n\n",
#      :filter => \&strip_head_eq,
#    },
#    :h2 => {
#      :curpat => '(?= *={2}[^=])',
#      :hint => ['=', ' '], 
#      :stops => '\n',
#      :contains => @@all_inline,
#      :open => "<h2>", :close => "</h2>\n\n",
#      :filter => \&strip_head_eq,
#    },
#    :h3 => {
#      :curpat => '(?= *={3}[^=])',
#      :hint => ['=', ' '], 
#      :stops => '\n',
#      :contains => @@all_inline,
#      :open => "<h3>", :close => "</h3>\n\n",
#      :filter => \&strip_head_eq,
#    },
#    :h4 => {
#      :curpat => '(?= *={4}[^=])',
#      :hint => ['=', ' '], 
#      :stops => '\n',
#      :contains => @@all_inline,
#      :open => "<h4>", :close => "</h4>\n\n",
#      :filter => \&strip_head_eq,
#    },
#    :h5 => {
#      :curpat => '(?= *={5}[^=])',
#      :hint => ['=', ' '], 
#      :stops => '\n',
#      :contains => @@all_inline,
#      :open => "<h5>", :close => "</h5>\n\n",
#      :filter => \&strip_head_eq,
#    },
#    :h6 => {
#      :curpat => '(?= *={6,})',
#      :hint => ['=', ' '], 
#      :stops => '\n',
#      :contains => @@all_inline,
#      :open => "<h6>", :close => "</h6>\n\n",
#      :filter => \&strip_head_eq,
#    },
#    :plain => {
#      :curpat => '(?=[^\*\/_\,\^\\\\{\[\<\|])',
#      :stops => @@inline,
#      :hint => @@plainchars,
#      :open => '', :close => ''
#    },
#    :any => { # catch-all
#      :curpat => '(?=.)',
#      :stops => @@inline,
#      :open => '', :close => ''
#    },
#    :br => {
#      :curpat => '(?=\\\\\\\\)',
#      :stops => '\\\\\\\\',
#      :hint => ['\\'],
#      :filter => sub { return ''; },
#      :open => '<br />', :close => '',
#    },
#    :esc => {
#      :curpat => '(?=~[\S])',
#      :stops => '~.',
#      :hint => ['~'],
#      :filter => sub { substr($_[0], 0, 1, ''); return $_[0]; },
#      :open => '', :close => '',
#    },
#    :inowiki => {
#      :curpat => '(?=\{{3}.*?\}*\}{3})',
#      :stops => '.*?\}*\}{3}',
#      :hint => ['{'],
#      :filter => sub {
#        substr($_[0], 0, 3, ''); 
#        $_[0] =~ s/\}{3}$//o;
#        $_[0] =~ s/&/&amp;/go;
#        $_[0] =~ s/</&lt;/go;
#        $_[0] =~ s/>/&gt;/go;
#        return $_[0];
#      },
#      :open => "<tt>", :close => "</tt>",
#    },
#    :plug => {
#      :curpat => '(?=\<{3}.*?\>*\>{3})',
#      :stops => '.*?\>*\>{3}',
#      :hint => ['<'],
#      :filter => sub {
#        substr($_[0], 0, 3, ''); 
#        $_[0] =~ s/\>{3}$//o;
#        if($plugin_function) {
#          return &$plugin_function($_[0]);
#        }
#        return "<<<$_[0]>>>";
#      },
#      :open => "", :close => "",
#    },
#    :plug2 => {
#      :curpat => '(?=\<{2}.*?\>*\>{2})',
#      :stops => '.*?\>*\>{2}',
#      :hint => ['<'],
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/\>{2}$//o;
#        if($plugin_function) {
#          return &$plugin_function($_[0]);
#        }
#        return "<<$_[0]>>";
#      },
#      :open => "", :close => "",
#    },
#    :ilink => {
#      :curpat => '(?=(?:https?|ftp):\/\/)',
#      :stops => '(?=[[:punct:]]?(?:\s|$))',
#      :hint => ['h', 'f'],
#      :filter => sub {
#        $_[0] =~ s/^\s*//o;
#        $_[0] =~ s/\s*$//o;
#        if($barelink_function) {
#          $_[0] = &$barelink_function($_[0]);
#        }
#        return "href=\"$_[0]\">$_[0]"; },
#      :open => "<a ", close=> "</a>",
#    },
#    :link => {
#      :curpat => '(?=\[\[[^\n]+?\]\])',
#      :stops => '\]\]',
#      :hint => ['['],
#      :contains => ['href', 'atext'],
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        substr($_[0], -2, 2, ''); 
#        $_[0] .= "|$_[0]" unless $_[0] =~ tr/|/|/; # text = url unless given
#        return $_[0];
#      },
#      :open => "<a ", :close => "</a>",
#    },
#    :href => {
#      :curpat => '(?=[^\|])',
#      :stops => '(?=\|)',
#      :filter => sub { 
#        $_[0] =~ s/^\s*//o; 
#        $_[0] =~ s/\s*$//o; 
#        if($link_function) {
#          $_[0] = &$link_function($_[0]);
#        }
#        return $_[0]; 
#      },
#      :open => 'href="', :close => '">',
#    },
#    :atext => {
#      :curpat => '(?=\|)',
#      :stops => '\n',
#      :hint => ['|'],
#      :contains => @@all_inline,
#      :filter => sub { 
#        $_[0] =~ s/^\|\s*//o; 
#        $_[0] =~ s/\s*$//o; 
#        return $_[0]; 
#      },
#      :open => '', :close => '',
#    },
#    :img => {
#      :curpat => '(?=\{\{[^\{][^\n]*?\}\})',
#      :stops => '\}\}',
#      :hint => ['{'],
#      :contains => ['imgsrc', 'imgalt'],
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/\}\}$//o;
#        return $_[0];
#      },
#      :open => "<img ", :close => " />",
#    },
#    :imgalt => {
#      :curpat => '(?=\|)',
#      :stops => '\n',
#      :hint => ['|'],
#      :filter => sub { $_[0] =~ s/^\|\s*//o; $_[0] =~ s/\s*$//o; return $_[0]; },
#      :open => ' alt="', :close => '"',
#    },
#    :imgsrc => {
#      :curpat => '(?=[^\|])',
#      :stops => '(?=\|)',
#      :filter => sub { 
#        $_[0] =~ s/^\s*//o; 
#        $_[0] =~ s/\s*$//o; 
#        if($img_function) {
#          $_[0] = &$img_function($_[0]);
#        }
#        return $_[0]; 
#      },
#      :open => 'src="', :close => '"',
#    },
#    :strong => {
#      :curpat => '(?=\*\*)',
#      :stops => '\*\*.*?\*\*',
#      :hint => ['*'],
#      :contains => @@all_inline,
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/\*\*$//o;
#        return $_[0];
#      },
#      :open => "<strong>", :close => "</strong>",
#    },
#    :em => {
#      :curpat => '(?=\/\/)',
#      :stops => '\/\/.*?(?<!:)\/\/',
#      :hint => ['/'],
#      :contains => @@all_inline,
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/\/\/$//o;
#        return $_[0];
#      },
#      :open => "<em>", :close => "</em>",
#    },
#    :mono => {
#      :curpat => '(?=\#\#)',
#      :stops => '\#\#.*?\#\#',
#      :hint => ['#'],
#      :contains => @@all_inline,
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/\#\#$//o;
#        return $_[0];
#      },
#      :open => "<tt>", :close => "</tt>",
#    },
#    :sub => {
#      :curpat => '(?=,,)',
#      :stops => ',,.*?,,',
#      :hint => [','],
#      :contains => @@all_inline,
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/\,\,$//o;
#        return $_[0];
#      },
#      :open => "<sub>", :close => "</sub>",
#    },
#    :sup => {
#      :curpat => '(?=\^\^)',
#      :stops => '\^\^.*?\^\^',
#      :hint => ['^'],
#      :contains => @@all_inline,
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/\^\^$//o;
#        return $_[0];
#      },
#      :open => "<sup>", :close => "</sup>",
#    },
#    :u => {
#      :curpat => '(?=__)',
#      :stops => '__.*?__',
#      :hint => ['_'],
#      :contains => @@all_inline,
#      :filter => sub {
#        substr($_[0], 0, 2, ''); 
#        $_[0] =~ s/__$//o;
#        return $_[0];
#      },
#      :open => "<u>", :close => "</u>",
#    },
#    :amp => {
#      :curpat => '(?=\&(?!\w+\;))',
#      :stops => '.',
#      :hint => ['&'],
#      :filter => sub { return "&amp;"; },
#      :open => "", :close => "",
#    },
#    :tm => {
#      :curpat => '(?=\(TM\))',
#      :stops => '\(TM\)',
#      :hint => ['('],
#      :filter => sub { return "&trade;"; },
#      :open => "", :close => "",
#    },
#    :reg => {
#      :curpat => '(?=\(R\))',
#      :stops => '\(R\)',
#      :hint => ['('],
#      :filter => sub { return "&reg;"; },
#      :open => "", :close => "",
#    },
#    :copy => {
#      :curpat => '(?=\(C\))',
#      :stops => '\(C\)',
#      :hint => ['('],
#      :filter => sub { return "&copy;"; },
#      :open => "", :close => "",
#    },
#    :ndash => {
#      :curpat => '(?=--)',
#      :stops => '--',
#      :hint => ['-'],
#      :filter => sub { return "&ndash;"; },
#      :open => "", :close => "",
#    },
#    :ellipsis => {
#      :curpat => '(?=\.\.\.)',
#      :stops => '\.\.\.',
#      :hint => ['.'],
#      :filter => sub { return "&hellip;"; },
#      :open => "", :close => "",
#    },
  }
  
  def self.filter_string_x_with_chunk_filter_y(str, chunk)
    return @@chunks_hash[chunk][:filter].call(str)
  end

end