# WikiCreole implements the Wiki Creole markup language, 
# version 1.0, as described at http://www.wikicreole.org.  It
# reads Creole 1.0 markup and returns XHTML.
#
# Author::    Gordon McCreight  (mailto:wikicreole.to.gordon@mccreight.com)
# Copyright:: Copyright (c) 2008 Gordon McCreight
# License::   Distributes under the same terms as Ruby (see the LICENSE file)
# Version:: 0.1.2
# Date:: 2008-12-12
#
# == Synopsis
# Most likely you'll just want to do:
#  require 'rubygems'
#  require 'wiki_creole'
#  xhtml = WikiCreole.creole_parse(wiki_creole_markup)
# If you want to override the default behaviors, make sure to look at the other
# public methods.
#
# == Official Markup
#
#  Here is a summary of the official Creole 1.0 markup 
#  elements.  See http://www.wikicreole.org for the full
#  details.
#
#  Headings:
#  = heading 1       ->    <h1>heading 1</h1>
#  == heading 2      ->    <h2>heading 2</h2>
#  ...
#  ====== heading 6  ->    <h6>heading 6</h6>
#
#  Various inline markup:
#  ** bold **        ->    <strong> bold </strong>
#  // italics //     ->    <em> italics </em>
#  **// both //**    ->    <strong><em> both </em></strong>
#  [[ link ]]        ->    <a href="link">link</a>
#  [[ link | text ]] ->    <a href="link">text</a>
#  http://cpan.org   ->    <a href="http://cpan.org">http://cpan.org</a>
#  line \\ break     ->    line <br /> break
#  {{img.jpg|alt}}   ->    <img src="img.jpg" alt="alt">
#
#  Lists:
#  * unordered list        <ul><li>unordered list</li>
#  * second item               <li>second item</li>
#  ## nested ordered  ->       <ol><li>nested ordered</li>
#  *** uber-nested                 <ul><li>uber-nested</li></ul>
#  * back to level 1           </ol><li>back to level 1</li></ul>
#
#  Tables:
#  |= h1 |= h2       ->    <table><tr><th>h1</th><th>h2</th></tr>
#  |  c1 |  c2             <tr><td>c1</td><td>c2</td></tr></table>
#
#  Nowiki (Preformatted):
#  {{{                     <pre>
#    ** not bold **          ** not bold **
#    escaped HTML:   ->      escaped HTML:
#    <i> test </i>           &lt;i&gt; test &lt;/i&gt;
#  }}}                     <pre>
#
#  {{{ inline\\also }}} -> <tt>inline\\also</tt>
#
#  Escape Character:
#  ~** not bold **    ->    ** not bold **
#  tilde: ~~          ->    tilde: ~
#
#  Paragraphs are separated by other blocks and blank lines.  
#  Inline markup can usually be combined, overlapped, etc.  List
#  items and plugin text can span lines.
#
# == Extended Markup
#
#  In addition to OFFICIAL MARKUP, Text::WikiCreole also supports
#  the following markup:
#
#  Plugins:
#  << plugin >>        ->    whatever you want (see WikiCreole.creole_plugin)
#  <<< plugin >>>      ->    whatever you want (see WikiCreole.creole_plugin)
#      Triple-bracket syntax has priority, in order to allow you to embed
#      double-brackets in plugins, such as to embed Perl code.
#
#  Inline:
#  ## monospace ##     ->    <tt> monospace </tt>
#  ^^ superscript ^^   ->    <sup> superscript </sup>
#  ,, subscript ,,     ->    <sub> subscript </sub>
#  __ underline __     ->    <u> underline </u>
#  (TM)                ->    &trade;
#  (R)                 ->    &reg;
#  (C)                 ->    &copy;
#  ...                 ->    &hellip;
#  --                  ->    &ndash;
#
#  Indented Paragraphs:
#  :this               ->    <div style="margin-left:2em"><p>this
#  is indented               is indented</p>
#  :: more indented          <div style="margin-left:2em"><p> more
#                            indented</div></div>
#
#  Definition Lists:
#  ; Title             ->    <dl><dt>Title</dt>
#  : item 1 : item 2         <dd>item 1</dd><dd>item 2</dd>
#  ; Title 2 : item2a        <dt>Title 2</dt><dd>item 2a</dd></dl>
#
# == Acknowledgements
# Most of this code is ported from Jason Burnett's excellent Perl-based
# converter which can be found here:
# http://search.cpan.org/~jburnett/Text-WikiCreole/
# He, in turn, acknowledges the Document::Parser perl module.
# 
# Also, some of the tests are taken from Lars Christensen's implementation of
# the Creole parser.  You can find his code at:
# http://github.com/larsch/creole/tree/master
#
# Other test come from the wikicreole website itself, here:
# http://www.wikicreole.org/

class WikiCreole
  
  # Reads Creole 1.0 markup and return XHTML.
  #
  # xhtml = WikiCreole.creole_parse(wiki_creole_markup)
  def self.creole_parse(s)
    return "" if s.class.to_s != "String"
    return "" if s.length < 1

    init
    return parse(s, :top)
  end
  
  # Creole 1.0 supports two plugin syntaxes: << plugin content >> and
  # <<< plugin content >>>
  # 
  # Write a function that receives the text between the <<>> 
  # delimiters (not including the delimiters) and 
  # returns the text to be displayed.  For example, here is a 
  # simple plugin that converts plugin text to uppercase:
  #
  #  uppercase = Proc.new {|s| 
  #    s.upcase!
  #    s
  #  }
  #  WikiCreole.creole_plugin(uppercase)
  #
  # If you do not register a plugin function, plugin markup will be left
  # as is, including the surrounding << >>.
  def self.creole_plugin(func)
    @plugin_function = func
  end

  # You may wish to customize [[ links ]], such as to prefix a hostname,
  # port, etc.
  #
  # Write a function, similar to the plugin function, which receives the
  # URL part of the link (with leading and trailing whitespace stripped) 
  # and returns the customized link.  For example, to prepend 
  #  http://my.domain/
  # to pagename:
  #
  #  mylink = Proc.new {|s| 
  #    s = "http://my.domain/" + s
  #    s
  #  }
  #  WikiCreole.creole_link(mylink)
  def self.creole_link(func)
    @link_function = func
  end
  
  # Same purpose as creole_link, but for "bare" link markup.  Bare links are
  # the links which are in the text but not surrounded by brackets.
  #
  #  mybarelink = Proc.new {|s| 
  #    s = s + ".html"
  #    s
  #  }
  #  WikiCreole.creole_barelink(mybarelink)
  def self.creole_barelink(func)
    @barelink_function = func
  end

  # Same purpose as creole_link, but for image URLs.
  #
  #  myimg = Proc.new {|s| 
  #    s = "http://my.domain/" + s
  #    s
  #  }
  #  WikiCreole.creole_img(myimg)
  def self.creole_img(func)
    @img_function = func
  end
  
  # If you want complete control over links, rather than just modifying
  # the URL, register your link markup function with WikiCreole.creole_link()
  # as above and then call creole_customlinks().  Now your function will receive
  # the entire link markup chunk, such as <tt>[[ some_wiki_page | page description ]]</tt> 
  # and must return HTML.
  #
  # This has no effect on "bare" link markup, such as
  #  http://cpan.org
  def self.creole_customlinks
    @@chunks_hash[:href][:open] = ""
    @@chunks_hash[:href][:close] = ""
    @@chunks_hash[:link][:open] = ""
    @@chunks_hash[:link][:close] = ""
    @@chunks_hash[:link].delete(:contains)
    @@chunks_hash[:link][:filter] = Proc.new {|s| 
      if @link_function
        s = @link_function.call(s)
      end
      s
    }
  end

  # Same purpose as creole_customlinks, but for "bare" link markup.
  def self.creole_custombarelinks
    @@chunks_hash[:ilink][:open] = ""
    @@chunks_hash[:ilink][:close] = ""
    @@chunks_hash[:ilink][:filter] = Proc.new {|s| 
      if @barelink_function
        s = @barelink_function.call(s)
      end
      s
    }
  end

  # Similar to creole_customlinks, but for images.
  def self.creole_customimgs
    @@chunks_hash[:img][:open] = ""
    @@chunks_hash[:img][:close] = ""
    @@chunks_hash[:img].delete(:contains)
    @@chunks_hash[:img][:filter] = Proc.new {|s| 
      if @img_function
        s = @img_function.call(s)
      end
      s
    }
  end
  
  # You may wish to customize the opening and/or closing tags
  # for the various bits of Creole markup.  For example, to
  # assign a CSS class to list items:
  #  WikiCreole.creole_tag(:li, :open, "<li class=myclass>")
  #
  # Or to see all current tags:
  #  puts WikiCreole.creole_tag()
  #
  # The tags that may be of interest are:
  #
  #  br          dd          dl
  #  dt          em          h1
  #  h2          h3          h4
  #  h5          h6          hr 
  #  ilink       img         inowiki
  #  ip          li          link
  #  mono        nowiki      ol
  #  p           strong      sub
  #  sup         table       td
  #  th          tr          u
  #  ul
  #
  # Those should be self-explanatory, except for inowiki (inline nowiki),
  # ilink (bare links, e.g.
  #  http://www.cpan.org
  # and ip (indented paragraph).
  def self.creole_tag(*args)
    
    # I bet a good Ruby hacker would know a way around this little chunk...
    tag = args.length > 0 ? args[0] : nil
    type = args.length > 1 ? args[1] : nil
    text = args.length > 2 ? args[2] : nil
    
    if tag.nil?
      tags = ""
      for key in @@chunks_hash.keys.collect{|x| x.to_s}.sort
        key = key.to_sym
        o = @@chunks_hash[key][:open]
        c = @@chunks_hash[key][:close]
        next if o.nil? || !o.index(/</m)
        o = o.gsub(/\n/m,"\\n")
        c = c.gsub(/\n/m,"\\n") if c
        c = "" if c.nil?
        this_tag = "#{key}: open(#{o}) close(#{c})\n"
        tags += this_tag
      end
      return tags
    else
      return if ! type
      type = type.to_sym
      return if type != :open && type != :close
      return if !@@chunks_hash.has_key?(tag)
      @@chunks_hash[tag][type] = text ? text : ""
    end
  end
  
  private
  
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
  
  # handy - used several times in %chunks
  @@eol = '(?:\n|$)'; # end of line (or string)
  
  @plugin_function = nil
  @barelink_function = nil
  @link_function = nil
  @img_function = nil
  
  @is_initialized = false

  @@chunks_hash = {
    :top => {
       :contains => @@blocks,
    },
    :blank => {
      :curpat => "(?= *#{@@eol})",
      :fwpat => "(?=(?:^|\\n) *#{@@eol})",
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
        s.sub!(/\n:/m, "\n")
        s
      },
      :open => "<div style=\"margin-left: 2em\">", :close => "</div>\n",
    },
    :dl => {
      :curpat => '(?=;)',
      :fwpat => '\n(?=;)',
      :stops => ['blank', 'h', 'hr', 'nowiki', 'ul', 'ol', 'table'],
      :hint => [';'],
      :contains => ['dt', 'dd'],
      :open => "<dl>\n", :close => "</dl>\n",
    },
    :dt => {
      :curpat => '(?=;)',
      :fwpat => '\n(?=;)',
      :stops => '(?=:|\n)',
      :hint => [';'],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s.sub!(/^;\s*/, '')
        s
      },
      :open => "  <dt>", :close => "</dt>\n",
    },
    :dd => {
      :curpat => '(?=\n|:)',
      :fwpat => '(?:\n|:)',
      :stops => '(?=:)|\n(?=;)',
      :hint => [':', "\n"],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s.sub!(/(?:\n|:)\s*/m, '')
        s.sub!(/\s*$/m, '')
        s
      },
      :open => "    <dd>", :close => "</dd>\n",
    },
    :table => {
      :curpat => '(?= *\|.)',
      :fwpat => '\n(?= *\|.)',
      :stops => '\n(?= *[^\|])',
      :contains => ['tr'],
      :hint => ['|', ' '],
      :open => "<table>\n", :close => "</table>\n\n",
    },
    :tr => {
      :curpat => '(?= *\|)',
      :stops => '\n',
      :contains => ['td', 'th'],
      :hint => ['|', ' '],
      :filter => Proc.new {|s|
        s.sub!(/^ */, '')
        s.sub!(/\| *$/, '')
        s
      },
      :open => "    <tr>\n", :close => "    </tr>\n",
    },
    :td => {
      :curpat => '(?=\|[^=])',
      # this gnarly regex fixes ambiguous '|' for links/imgs/nowiki in tables
      :stops => '[^~](?=\|(?!(?:[^\[]*\]\])|(?:[^\{]*\}\})))',
      :contains => @@all_inline,
      :hint => ['|'],
      :filter => Proc.new {|s|
        s.sub!(/^ *\| */, '')
        s.sub!(/\s*$/m, '')
        s
      },
      :open => "        <td>", :close => "</td>\n",
    },
    :th => {
      :curpat => '(?=\|=)',
      # this gnarly regex fixes ambiguous '|' for links/imgs/nowiki in tables
      :stops => '[^~](?=\|(?!(?:[^\[]*\]\])|(?:[^\{]*\}\})))',
      :contains => @@all_inline,
      :hint => ['|'],
      :filter => Proc.new {|s|
        s.sub!(/^ *\|= */, '')
        s.sub!(/\s*$/m, '')
        s
      },
      :open => "        <th>", :close => "</th>\n",
    },
    :ul => {
      :curpat => '(?=(?:`| *)\*[^\*])',
      :fwpat => '(?=\n(?:`| *)\*[^\*])',
      :stops => ['blank', 'ip', 'h', 'nowiki', 'li', 'table', 'hr', 'dl'],
      :contains => ['ul', 'ol', 'li'],
      :hint => ['*', ' '],
      :filter => Proc.new {|s|
        s = strip_list(s)
        s
      },
      :open => "<ul>\n", :close => "</ul>\n",
    },
    :ol => {
      :curpat => '(?=(?:`| *)\#[^\#])',
      :fwpat => '(?=\n(?:`| *)\#[^\#])',
      :stops => ['blank', 'ip', 'h', 'nowiki', 'li', 'table', 'hr', 'dl'],
      :contains => ['ul', 'ol', 'li'],
      :hint => ['#', ' '],
      :filter => Proc.new {|s|
        s = strip_list(s)
        s
      },
      :open => "<ol>\n", :close => "</ol>\n",
    },
    :li => {
      :curpat => '(?=`[^\*\#])',
      :fwpat => '\n(?=`[^\*\#])',
      :stops => '\n(?=`)',
      :hint => ['`'],
      :filter => Proc.new {|s|
        s.sub!(/` */, '')
        s.chomp!
        s
      },
      :contains => @@all_inline,
      :open => "    <li>", :close => "</li>\n",
    },
    :nowiki => {
      :curpat => '(?=\{\{\{ *\n)',
      :fwpat => '\n(?=\{\{\{ *\n)',
      :stops => "\\n\\}\\}\\} *#{@@eol}",
      :hint => ['{'],
      :filter => Proc.new {|s|
        s[0,3] = ''
        s.sub!(/\}{3}\s*$/, '')
        s.gsub!(/&/, '&amp;')
        s.gsub!(/</, '&lt;')
        s.gsub!(/>/, '&gt;')
        s
      },
      :open => "<pre>", :close => "</pre>\n\n",
    },
    :hr => {
      :curpat => "(?= *-{4,} *#{@@eol})",
      :fwpat => "\\n(?= *-{4,} *#{@@eol})",
      :hint => ['-', ' '],
      :stops => @@eol,
      :open => "<hr />\n\n", :close => "",
      :filter => Proc.new { "" } # ----- into the bit bucket
    },
    :h => { :curpat => '(?=(?:^|\n) *=)' }, # matches any heading
    :h1 => {
      :curpat => '(?= *=[^=])',
      :hint => ['=', ' '], 
      :stops => '\n',
      :contains => @@all_inline,
      :open => "<h1>", :close => "</h1>\n\n",
      :filter => Proc.new {|s|
        s = strip_leading_and_trailing_eq_and_whitespace(s)
        s
      },
    },
    :h2 => {
      :curpat => '(?= *={2}[^=])',
      :hint => ['=', ' '], 
      :stops => '\n',
      :contains => @@all_inline,
      :open => "<h2>", :close => "</h2>\n\n",
      :filter => Proc.new {|s|
        s = strip_leading_and_trailing_eq_and_whitespace(s)
        s
      },
    },
    :h3 => {
      :curpat => '(?= *={3}[^=])',
      :hint => ['=', ' '], 
      :stops => '\n',
      :contains => @@all_inline,
      :open => "<h3>", :close => "</h3>\n\n",
      :filter => Proc.new {|s|
        s = strip_leading_and_trailing_eq_and_whitespace(s)
        s
      },
    },
    :h4 => {
      :curpat => '(?= *={4}[^=])',
      :hint => ['=', ' '], 
      :stops => '\n',
      :contains => @@all_inline,
      :open => "<h4>", :close => "</h4>\n\n",
      :filter => Proc.new {|s|
        s = strip_leading_and_trailing_eq_and_whitespace(s)
        s
      },
    },
    :h5 => {
      :curpat => '(?= *={5}[^=])',
      :hint => ['=', ' '], 
      :stops => '\n',
      :contains => @@all_inline,
      :open => "<h5>", :close => "</h5>\n\n",
      :filter => Proc.new {|s|
        s = strip_leading_and_trailing_eq_and_whitespace(s)
        s
      },
    },
    :h6 => {
      :curpat => '(?= *={6,})',
      :hint => ['=', ' '], 
      :stops => '\n',
      :contains => @@all_inline,
      :open => "<h6>", :close => "</h6>\n\n",
      :filter => Proc.new {|s|
        s = strip_leading_and_trailing_eq_and_whitespace(s)
        s
      },
    },
    :plain => {
      :curpat => '(?=[^\*\/_\,\^\\\\{\[\<\|])',
      :stops => @@inline,
      :hint => @@plainchars,
      :open => '', :close => ''
    },
    :any => { # catch-all
      :curpat => '(?=.)',
      :stops => @@inline,
      :open => '', :close => ''
    },
    :br => {
      :curpat => '(?=\\\\\\\\)',
      :stops => '\\\\\\\\',
      :hint => ['\\'],
      :filter => Proc.new { "" },
      :open => '<br />', :close => '',
    },
    :esc => {
      :curpat => '(?=~[\S])',
      :stops => '~.',
      :hint => ['~'],
      :filter => Proc.new {|s|
        s.sub!(/^./m, '')
        s
      },
      :open => '', :close => '',
    },
    :inowiki => {
      :curpat => '(?=\{{3}.*?\}*\}{3})',
      :stops => '.*?\}*\}{3}',
      :hint => ['{'],
      :filter => Proc.new {|s|
        s[0,3] = ''
        s.sub!(/\}{3}\s*$/, '')
        s.gsub!(/&/, '&amp;')
        s.gsub!(/</, '&lt;')
        s.gsub!(/>/, '&gt;')
        s
      },
      :open => "<tt>", :close => "</tt>",
    },
    :plug => {
      :curpat => '(?=\<{3}.*?\>*\>{3})',
      :stops => '.*?\>*\>{3}',
      :hint => ['<'],
      :filter => Proc.new {|s|
        s[0,3] = ''
        s.sub!(/\>{3}$/, '')
        if !@plugin_function.nil?
          s = @plugin_function.call(s)
        else
          s = "<<<#{s}>>>"
        end
        s
      },
      :open => "", :close => "",
    },
    :plug2 => {
      :curpat => '(?=\<{2}.*?\>*\>{2})',
      :stops => '.*?\>*\>{2}',
      :hint => ['<'],
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/\>{2}$/, '')
        if !@plugin_function.nil?
          s = @plugin_function.call(s)
        else
          s = "<<#{s}>>"
        end
        s
      },
      :open => "", :close => "",
    },
    :ilink => {
      :curpat => '(?=(?:https?|ftp):\/\/)',
      # This following is the [:punct:] character class with the / and ? removed
      # so that URLs like http://www.somesite.com/ will match the trailing
      # slash.  URLs with a trailing ? will also work.  Trailing ? is sometimes
      # used to ensure that browsers don't cache the page.
      :stops => '(?=[!"#$%&\'()*+,-.:;<=>@\[\\]^_`{|}~]?(?:\s|$))',
      :hint => ['h', 'f'],
      :filter => Proc.new {|s|
        s.sub!(/^\s*/, '')
        s.sub!(/\s*$/, '')
        if !@barelink_function.nil?
          s = @barelink_function.call(s)
        end  
        s = "href=\"#{s}\">#{s}"
        s
      },
      :open => "<a ", :close=> "</a>",
    },
    :link => {
      :curpat => '(?=\[\[[^\n]+?\]\])',
      :stops => '\]\]',
      :hint => ['['],
      :contains => ['href', 'atext'],
      :filter => Proc.new {|s|
        s[0,2] = ''
        s[-2,2] = ''
        s += "|#{s}" if ! s.index(/\|/) # text = url unless given
        s      
      },
      :open => "<a ", :close => "</a>",
    },
    :href => {
      :curpat => '(?=[^\|])',
      :stops => '(?=\|)',
      :filter => Proc.new {|s|
        s.sub!(/^\s*/, '')
        s.sub!(/\s*$/, '')
        if !@link_function.nil?
          s = @link_function.call(s)
        end
        s
      },
      :open => 'href="', :close => '">',
    },
   :atext => {
      :curpat => '(?=\|)',
      :stops => '\n',
      :hint => ['|'],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s.sub!(/^\|\s*/, '')
        s.sub!(/\s*$/, '')
        s
      },
      :open => '', :close => '',
   },
   :img => {
      :curpat => '(?=\{\{[^\{][^\n]*?\}\})',
      :stops => '\}\}',
      :hint => ['{'],
      :contains => ['imgsrc', 'imgalt'],
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/\}\}$/, '')
        s
      },
      :open => "<img ", :close => " />",
   },
   :imgalt => {
      :curpat => '(?=\|)',
      :stops => '\n',
      :hint => ['|'],
      :filter => Proc.new {|s|
        s.sub!(/^\|\s*/, '')
        s.sub!(/\s*$/, '')
        s
      },
      :open => ' alt="', :close => '"',
   },
   :imgsrc => {
      :curpat => '(?=[^\|])',
      :stops => '(?=\|)',
      :filter => Proc.new {|s|
        s.sub!(/^\|\s*/, '')
        s.sub!(/\s*$/, '')
        if !@img_function.nil?
          s = @img_function.call(s)
        end
        s
      },
      :open => 'src="', :close => '"',
   },
    :strong => {
      :curpat => '(?=\*\*)',
      :stops => '\*\*.*?\*\*',
      :hint => ['*'],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/\*\*$/, '')
        s
      },
      :open => "<strong>", :close => "</strong>",
    },
    :em => {
      # This could use a negative lookback assertion to let you know whether
      # it's part of a URL or not.  That would be helpful if the URL had been
      # escaped.  Currently, it will just become italic after the // since 
      # it didn't process the URL.
      :curpat => '(?=\/\/)',
      # Removed a negative lookback assertion (?<!:) from the Perl version
      # and replaced it with [^:]  Not sure of the consequences, however, as
      # of this version, Ruby does not have negative lookback assertions, so
      # I had to do it.
      :stops => '\/\/.*?[^:]\/\/',
      :hint => ['/'],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/\/\/$/, '')
        s
      },
      :open => "<em>", :close => "</em>",
    },
    :mono => {
      :curpat => '(?=\#\#)',
      :stops => '\#\#.*?\#\#',
      :hint => ['#'],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/\#\#$/, '')
        s
      },
      :open => "<tt>", :close => "</tt>",
    },
    :sub => {
      :curpat => '(?=,,)',
      :stops => ',,.*?,,',
      :hint => [','],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/\,\,$/, '')
        s
      },
      :open => "<sub>", :close => "</sub>",
    },
    :sup => {
      :curpat => '(?=\^\^)',
      :stops => '\^\^.*?\^\^',
      :hint => ['^'],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/\^\^$/, '')
        s
      },
      :open => "<sup>", :close => "</sup>",
    },
    :u => {
      :curpat => '(?=__)',
      :stops => '__.*?__',
      :hint => ['_'],
      :contains => @@all_inline,
      :filter => Proc.new {|s|
        s[0,2] = ''
        s.sub!(/__$/, '')
        s
      },
      :open => "<u>", :close => "</u>",
    },
    :amp => {
      :curpat => '(?=\&(?!\w+\;))',
      :stops => '.',
      :hint => ['&'],
      :filter => Proc.new { "&amp;" },
      :open => "", :close => "",
    },
    :tm => {
      :curpat => '(?=\(TM\))',
      :stops => '\(TM\)',
      :hint => ['('],
      :filter => Proc.new { "&trade;" },
      :open => "", :close => "",
    },
    :reg => {
      :curpat => '(?=\(R\))',
      :stops => '\(R\)',
      :hint => ['('],
      :filter => Proc.new { "&reg;" },
      :open => "", :close => "",
    },
    :copy => {
      :curpat => '(?=\(C\))',
      :stops => '\(C\)',
      :hint => ['('],
      :filter => Proc.new { "&copy;" },
      :open => "", :close => "",
    },
    :ndash => {
      :curpat => '(?=--)',
      :stops => '--',
      :hint => ['-'],
      :filter => Proc.new { "&ndash;" },
      :open => "", :close => "",
    },
    :ellipsis => {
      :curpat => '(?=\.\.\.)',
      :stops => '\.\.\.',
      :hint => ['.'],
      :filter => Proc.new { "&hellip;" },
      :open => "", :close => "",
    },
  }
  
  def self.strip_leading_and_trailing_eq_and_whitespace(s)
    s.sub!(/^\s*=*\s*/, '')
    s.sub!(/\s*=*\s*$/, '')
    return s
  end

  def self.strip_list(s)
    s.sub!(/(?:`*| *)[\*\#]/, '`')
    s.gsub!(/\n(?:`*| *)[\*\#]/m, "\n`")
    return s
  end
  
  def self.filter_string_x_with_chunk_filter_y(str, chunk)
    return @@chunks_hash[chunk][:filter].call(str)
  end
  
  def self.get_next_pos_for_chunk_type(tref, chunk, starting_pos, last_pos)
  
    pos = starting_pos
    
    if chunk == :dd
      # Yuck... I don't exactly understand why I need this section, but
      # without it the parser will go into an infinite loop on the :dd's in
      # the test suite.  Please, if you're a most excellent Ruby hacker,
      # find the issue, clean this up, and remove the comment here, m'kay?
      
      while tref.index(Regexp.compile('\G.*' + @@chunks_hash[chunk][:delim], Regexp::MULTILINE), pos)
        end_of_match = Regexp.last_match.end(0)
        if end_of_match == pos
          break
        else
          pos = end_of_match
        end
      end

      if pos == last_pos
        pos = tref.length
      end
    else
      # This is a little slower than it could be.  The delim should be
      # pre-compiled, but see the issue in the comment above.
      
      #puts chunk
      #puts @@chunks_hash[chunk][:delim]
      
      if tref.index(Regexp.compile(@@chunks_hash[chunk][:delim], Regexp::MULTILINE), pos)
        pos = Regexp.last_match.end(0)
      else 
        pos = tref.length
      end
    end
    return pos
  end
  
  def self.parse(tref, chunk)
  
    sub_chunk = nil
    pos = 0
    last_pos = 0
    html = ""
    first_try = true

    loop do

      if sub_chunk # we've determined what type of sub_chunk this is
        
        pos = self.get_next_pos_for_chunk_type(tref, sub_chunk, pos, last_pos)

        html += @@chunks_hash[sub_chunk][:open]

        t = tref[last_pos, pos - last_pos] # grab the chunk

        if @@chunks_hash[sub_chunk].has_key?(:filter)   # filter it, if applicable
          t = @@chunks_hash[sub_chunk][:filter].call(t)
        end
        
        last_pos = pos  # remember where this chunk ends (where next begins)
        
        if t && @@chunks_hash[sub_chunk].has_key?(:contains)  # if it contains other chunks...
          html += parse(t, sub_chunk)         #    recurse.
        else
          html += t                    # otherwise, print it
        end
        
        html += @@chunks_hash[sub_chunk][:close]       # print the close tag
      
      else
        if !first_try
          $stderr.puts "ERROR: endless loop detected"
          #$stderr.puts "ERROR: tref is ->" + tref.to_s
          #$stderr.puts "ERROR: chunk is ->" + chunk.to_s
          break
        end
        first_try = false
      end

      if pos && pos == tref.length # we've eaten the whole string
        break
      else ## more string to come
        sub_chunk = get_sub_chunk_for(tref, chunk, pos)
      end

    end
    
    return html
  end
  
  def self.get_sub_chunk_for(tref, chunk, pos)

    first_char = tref[pos, 1] # get a hint about the next chunk
    for chunk_hinted_at in @@chunks_hash[chunk][:calculated_hint_array_for][first_char].to_a
      #puts "trying hint #{chunk_hinted_at} for -#{first_char}- on -" + tref[pos, 2] + "-\n"
      if tref.index(@@chunks_hash[chunk_hinted_at][:curpatcmp], pos) # hint helped id the chunk
        return chunk_hinted_at
      end
    end

    # the hint didn't help. Check all the chunk types which this chunk contains
    for contained_chunk in @@chunks_hash[chunk][:contains].to_a
      #puts "trying contained chunk #{contained_chunk} on -" + tref[pos, 2] + "- within chunk #{chunk.to_s}\n"
      if tref.index(@@chunks_hash[contained_chunk.to_sym][:curpatcmp], pos) # found one
        return contained_chunk.to_sym
      end
    end
    
    return nil
  end
  
  # compile a regex that matches any of the patterns that interrupt the
  # current chunk.
  def self.delim(chunk)
    chunk = @@chunks_hash[chunk]
    if chunk[:stops].class.to_s == "Array"
      regex = ''
      for stop in chunk[:stops]
        stop = stop.to_sym
        if @@chunks_hash[stop].has_key?(:fwpat)
          regex += @@chunks_hash[stop][:fwpat] + "|"
        else
          regex += @@chunks_hash[stop][:curpat] + "|"
        end
      end
      regex.chop!
      return regex
    else
      return chunk[:stops]
    end
  end
  
  # one-time optimization of the grammar - speeds the parser up a ton
  def self.init 
    return if @is_initialized

    @is_initialized = true

    # build an array of "plain content" characters by subtracting @specialchars
    # from ascii printable (ascii 32 to 126)
    for charnum in 32..126 do
      char = charnum.chr
      if @@specialchars.index(char).nil?
        @@plainchars << char
      end
    end

    # precompile a bunch of regexes 
    for k in @@chunks_hash.keys do
      c = @@chunks_hash[k]
      if c.has_key?(:curpat)
        c[:curpatcmp] = Regexp.compile('\G' + c[:curpat], Regexp::MULTILINE)
      end
      
      if c.has_key?(:stops)
        c[:delim] = delim(k)
      end
      
      if c.has_key?(:contains) # store hints about each chunk to speed id
        c[:calculated_hint_array_for] = {}
        
        for ct in c[:contains]
          ct = ct.to_sym
          
          if @@chunks_hash[ct].has_key?(:hint)
            for hint in @@chunks_hash[ct][:hint]
              if !c[:calculated_hint_array_for].has_key?(hint)
                c[:calculated_hint_array_for][hint] = []
              end
              c[:calculated_hint_array_for][hint] << ct
            end
          end

        end
      end
    end
  end
end
