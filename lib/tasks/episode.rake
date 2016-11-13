require_relative '../episode.rb'

namespace :episode do
  desc 'Create new episode'
  task :create do
    puts 'task: Create new episode'
    Episode.new.create
  end
end
