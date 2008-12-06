use Text::WikiCreole;
#$html = creole_parse 

$str = "//Hello// **Hello**";
if ( $str =~ /(?s-xim:\G(?=(?:`| *)\*[^\*]))/ ) {
  print "parsed it\n";
}