require 'logger'
require 'aistaimgcrawler'
require 'dotenv'
require 'mysql'
require './lib/client'

class Base
  module Status
    CREATED    = 1
    RETRIEVED  = 2
    REGISTERED = 3
    FINISHED   = 4
  end

  def initialize
    Dotenv.load
    Dotenv.load ENV['AISTA_ENV'] # Fetch api key

    img_dir = './img/'
    @logger = Logger.new('job.log')
    @crawler = crawler.new(@logger, img_dir)
    @clnt = Client.new(img_dir, @logger, ENV['BASE_URI'], ENV['API_TOKEN'])
  end

  def crawler type="ponpokonwes"
    case ENV['CRAWLER_TYPE'] || type
    when "ponpokonwes"
      Aistaimgcrawler::Ponpokonwes
    when "aikatunews"
      Aistaimgcrawler::Aikatunews
    end
  end

  def next_status(status)
    status == Status::FINISHED ? Status::CREATED : status + 1
  end
end
