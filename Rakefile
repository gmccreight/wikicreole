require 'rake'
require 'rake/clean'

desc "Testing library (pure ruby)"
task :default => :clean do
  ruby '-v -I lib tests/runner.rb'
end

# I like the look of the following, however it doesn't appear to work correctly

#require 'rake'
#require 'rake/testtask'

#Rake::TestTask.new do |t|
#   t.libs << 'lib'
#   t.warning = true
#   t.test_files = FileList['test/tc*']
#end