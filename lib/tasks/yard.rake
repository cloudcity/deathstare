namespace :deathstare do
  require 'yard'
  require 'deathstare'
  deathstare_path = Gem.loaded_specs['deathstare'].full_gem_path  
  YARD::Rake::YardocTask.new do |t|
    t.options = %w[ -o public/doc -m markdown --files *.md app lib ] <<
      "#{deathstare_path}/app" << "#{deathstare_path}/lib"
  end
end
