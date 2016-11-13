Dir[Dir.pwd+'/lib/tasks/**/*.rake'].each do |path|
  load path
end

task :default => :weekly

task :weekly do
  Rake::Task["episode:create"].invoke
  Rake::Task["image:retrieve"].invoke
  Rake::Task["image:register"].invoke
  Rake::Task["image:thumb"].invoke
end
