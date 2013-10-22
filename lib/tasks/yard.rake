namespace :deathstar do
  require 'yard'
  YARD::Rake::YardocTask.new { |t| t.options = %w[ -o public/doc -m markdown --files *.md ] }
end
