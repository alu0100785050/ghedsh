require 'bundler/gem_tasks'
#require 'rspec/core/rake_task'

#RSpec::Core::RakeTask.new(:spec)

task default: :bash

desc "Run simple interace"
task :bash do
	sh "ruby bin/ghedsh"
end


desc "publish gem"
task :publish do
  sh "rm ghedsh-*.gem"
  sh "gem build ghedsh.gemspec"
  sh "gem push ghedsh-*.gem"
end
