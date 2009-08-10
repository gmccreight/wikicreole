# -*- encoding: utf-8 -*-

# You can create a new release using this file by calling:
# gem build wiki_creole_gemspec.rb

files = %W{
  README
  Changelog
  COPYING
  LICENSE
  Rakefile
  lib/wiki_creole.rb
}

test_files = %W{
  test/profiling.rb
  test/test_release_attributes.rb
  test/test_all.rb
  test/test_amp.markup           test/test_amp.html
  test/test_block.markup         test/test_block.html
  test/test_escape.markup        test/test_escape.html
  test/test_inline.markup        test/test_inline.html
  test/test_jsp_wiki.markup      test/test_jsp_wiki.html
  test/test_nested_lists.markup  test/test_nested_lists.html
  test/test_specialchars.markup  test/test_specialchars.html
}

Gem::Specification.new do |s|
  s.name = %q{WikiCreole}
  s.version = %q{0.1.3}
  
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version
  
  s.authors = ["Gordon McCreight"]
  s.date = %q{2009-02-05}
  s.description = %q{A Creole-to-XHTML converter written in pure Ruby}
  s.email = %q{gordon@mccreight.com}
  s.extra_rdoc_files = %W{README LICENSE}
  s.files = files
  s.has_rdoc = true
  s.homepage = %q{http://github.com/gmccreight/wikicreole/}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{wikicreole}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{A Creole-to-XHTML converter written in pure Ruby}
  s.test_files = test_files
 
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
  end

end