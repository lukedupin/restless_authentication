require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require "#{File.dirname(__FILE__)}/tasks/restless_authentication.rake"

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_when_authorized plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_when_authorized plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'RestlessAuthentication'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
