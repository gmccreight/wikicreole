# You can create a new release using this file by calling:
# gem build wiki_creole_gemspec.rb

# Read the actual code to get the version and the date
code = File.read("lib/wiki_creole.rb")
version_from_code = code.match(/Version:: *(\d+\.\d+\.\d+)/m)[1]
date_from_code = code.match(/Date:: *(\d+-\d+-\d+)/m)[1]

# Read the first line of the Changelog to make sure it matches with the code's version and date.  This ensures
# that everything is in sync for the release.
changelog = File.read("Changelog")
matches = changelog.match(/^ *(\d+-\d+-\d+) *\((\d+\.\d+\.\d+)\)/)
date_from_changelog = matches[1]
version_from_changelog = matches[2]

had_errors = false

if version_from_code != version_from_changelog
  puts "  The version in the code --->#{version_from_code}<--- is not the
  same as the version at the top of the Changelog --->#{version_from_changelog}<---"
  had_errors = true
end

if date_from_code != date_from_changelog
  puts "  The date in the code --->#{date_from_code}<--- is not the
  same as the date at the top of the Changelog --->#{date_from_changelog}<---"
  had_errors = true
end

if File.exists?("releases/WikiCreole-#{version_from_code}.gem")
  puts "  It looks like the WikiCreole-#{version_from_code}.gem file was already released.
  Look in the 'releases' folder to see it."
  had_errors = true
end

if File.exists?("WikiCreole-#{version_from_code}.gem")
  puts "  It looks like the WikiCreole-#{version_from_code}.gem file was already created, but maybe not released.
  Look in the project's root folder.  If it was actually released, you should move it to the 'releases' folder.
  Otherwise, if you just want to re-create the gem file, then delete the pre-existing one and run the command again."
  had_errors = true
end

# If there were any errors, don't actually do the build.
if had_errors
  puts "BUILD ABORTED because of the errors listed above"
  exit
end

files = %W{
  README
  Changelog
  COPYING
  LICENSE
  Rakefile
  lib/wiki_creole.rb
  test/test_all.rb        test/test_escape.html    test/test_jsp_wiki.markup
  test/test_amp.html      test/test_escape.markup  test/test_specialchars.html
  test/test_amp.markup    test/test_inline.html    test/test_specialchars.markup
  test/test_block.html    test/test_inline.markup
  test/test_block.markup  test/test_jsp_wiki.html
  test/profiling.rb
}

Gem::Specification.new do |s|
   s.name = %q{WikiCreole}
   s.version = version_from_code
   s.date = date_from_code
   s.authors = ["Gordon McCreight"]
   s.email = %q{gordon@mccreight.com}
   s.has_rdoc = true
   s.require_path = "lib"
   s.summary = %q{A Creole-to-XHTML converter written in pure Ruby}
   s.homepage = %q{http://github.com/gmccreight/wikicreole/tree/master}
   s.description = %q{A Creole-to-XHTML converter written in pure Ruby}
   s.files = files
   s.test_files = "test/test_all.rb".to_a
end