require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "smartfox"
    gem.summary = %Q{Client library for SmartFoxServer}
    gem.description = %Q{Provides a client library for the SmartFox realtime communication server, including BlueBox extensions.}
    gem.email = "self@richardpenwell.me"
    gem.homepage = "http://github.com/penwellr/smartfox"
    gem.authors = ["Richard Penwell"]
    gem.add_development_dependency "rspec", "~> 2.0"
    gem.add_dependency 'json'
    gem.add_dependency 'builder'
    gem.add_dependency 'libxml-ruby'
    gem.files.exclude 'nbproject/**'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/**/*_spec.rb']
  end

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
    spec.rcov_opts = ['--exclude', "features,kernel,load-diff-lcs\.rb,instance_exec\.rb,lib/spec.rb,lib/spec/runner.rb,^spec/*,bin/spec,examples,/gems,/Library/Ruby,\.autotest,#{ENV['GEM_HOME']}"]
  end
rescue
  puts "Rspec ~> 2.0 (or a dependency) is not available.  Install it with: gem install rspec"
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "smartfox #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :gem => :build