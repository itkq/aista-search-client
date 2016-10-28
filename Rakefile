require 'logger'
require 'aistaimgcrawler'
require 'dotenv'
require 'mysql'
require_relative 'client'

module Status
  CREATED     = 1
  RETRIEVED   = 2
  REGISTERED  = 3
end

Dotenv.load
Dotenv.load ENV['AISTA_ENV'] # Fetch api key

Dir[Dir.pwd+'/lib/tasks/**/*.rake'].each do |path|
  load path
end

img_dir = './img/'
@logger = Logger.new('job.log')
@crawler = Aistaimgcrawler::Ponpokonwes.new(@logger, img_dir)
@clnt = Client.new(img_dir, @logger, ENV['BASE_URI'], ENV['API_TOKEN'])

task :default => :daily

task :daily do
  Rake::Task["episode:fetch"].invoke
  Rake::Task["episode:create"].invoke
end

