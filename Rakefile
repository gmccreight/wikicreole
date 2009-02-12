require 'rake'
require 'rake/testtask'

desc "Default Task"
task :default => :test_all

desc "Test Task"
task :test => :test_all

desc "Check - same as test_all"
task :check => :test_all

Rake::TestTask.new(:test_all) do |t|
  t.libs << 'lib'
  t.warning = true
  t.test_files = FileList['test/test_all.rb']
end

# When running the profiling task in Cygwin, this command line
# makes it easy to view the results in the browser:
# rake profiling ; "/cygdrive/c/Program Files/Mozilla Firefox/firefox.exe" profiling.html
Rake::TestTask.new(:profiling) do |t|
  t.libs << 'lib'
  t.warning = true
  t.test_files = FileList['test/profiling.rb']
end