#!/usr/bin/env ruby

require 'test/unit'

class TC_WikiCreole < Test::Unit::TestCase

  def setup

    # Read the actual library code to get the version and the date
    code = File.read("lib/wiki_creole.rb")
    @version_from_code = code.match(/Version:: *(\d+\.\d+\.\d+)/)[1]
    @date_from_code = code.match(/Date:: *(\d+-\d+-\d+)/)[1]

    # Read the first line of the Changelog to get the version and the date
    changelog = File.read("Changelog")
    matches = changelog.match(/^ *(\d+-\d+-\d+) *\((\d+\.\d+\.\d+)\)/)
    @date_from_changelog = matches[1]
    @version_from_changelog = matches[2]
    
    # Read the gemspec file to get the version and the date
    gemspec = File.read("wikicreole.gemspec")
    @version_from_gemspec = gemspec.match(/s\.version.*?(\d+\.\d+\.\d+)/)[1]
    @date_from_gemspec = gemspec.match(/s\.date.*?(\d+-\d+-\d+)/)[1]

  end
  
  def test_versions_are_the_same_in_all_files
    assert_equal @version_from_code, @version_from_changelog
    assert_equal @version_from_changelog, @version_from_gemspec
  end
  
  def test_dates_are_the_same_in_all_files
    assert_equal @date_from_code, @date_from_changelog
    assert_equal @date_from_changelog, @date_from_gemspec
  end

end
