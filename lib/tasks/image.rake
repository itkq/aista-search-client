require_relative '../image.rb'
namespace :image do

  desc 'Retrieve images'
  task :retrieve do
    puts 'task: Retrieve images'
    Image.new.retrieve
  end

  desc 'Register images'
  task :register do
    puts 'task: Register images'
    Image.new.register
  end

  desc 'Create thumbnail'
  task :thumb do
    puts 'task: Create thumbmnail'
    Image.new.create_thumbnail
  end
end
