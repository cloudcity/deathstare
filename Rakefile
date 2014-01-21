begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'deathstare/engine'
require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Deathstare'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

task default: :spec

require 'rspec/core/rake_task'
desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(spec: 'app:db:test:prepare')

# stolen straight from gems/rspec-rails-2.14.0/lib/rspec/rails/tasks/rspec.rake
namespace :spec do
  types = begin
    dirs = Dir['./spec/**/*_spec.rb'].
      map { |f| f.sub(/^\.\/(spec\/\w+)\/.*/, '\\1') }.
      uniq.
      select { |f| File.directory?(f) }
    Hash[dirs.map { |d| [d.split('/').last, d] }]
  end

  types.each do |type, dir|
    desc "Run the code examples in #{dir}"
    RSpec::Core::RakeTask.new(type => 'app:db:test:prepare') do |t|
      t.pattern = "./#{dir}/**/*_spec.rb"
    end
  end
end

