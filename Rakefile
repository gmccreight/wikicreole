require 'rake'
require 'rake/testtask'

desc "Default Task"
task :default => :test_all

Rake::TestTask.new(:test_all) do |t|
  t.libs << 'lib'
  t.warning = true
  t.test_files = FileList['test/test_all.rb']
end

#note, to build the gem, use:
#gem build wiki_creole.gemspec