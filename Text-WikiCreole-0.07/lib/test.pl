#!/usr/bin/perl

use strict;
use warnings;

use Text::WikiCreole;

my $markup = "; First title of definition list: Definition of first item.";

my $html = creole_parse $markup;
print $html . "\n";