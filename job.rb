require 'dotenv'
require './scraper'
require './client'
require './cloudvision'

class Job
  INITIALIZED = 0
  CREATED     = 1
  RETRIEVED   = 2
  REGISTERED  = 3

  FUNCS = [
    "create_episode",
    "retrieve_images",
    "register_sentence"
  ].freeze

  def initialize
    Dotenv.load
    @scr = Scraper.new(ENV['APP_DIR'])
    @clnt = Client.new
  end

  def main
    ep = @clnt.get_latest_episode
    unless ep
      ep = {"id" => 1, "status" => INITIALIZED}
    end

    # set target episode
    if ep["status"] != REGISTERED
      episode_id, status = ep["id"], ep["status"]
    else
      episode_id, status = ep["id"] + 1, INITIALIZED
    end
    puts "target episode: #{episode_id}, status: #{status}"

    while status != REGISTERED
      puts "[#{FUNCS[status]}]"
      self.send(FUNCS[status], episode_id)
      status += 1
    end

  end

  def create_episode episode_id
    article = @scr.get_article_by_episode(episode_id)

    unless @clnt.create_episode(episode_id, article[:title])
      raise "error: create episode ##{episode_id} #{article[:title]}"
    end
  end

  def retrieve_images episode_id
    article = @scr.get_article_by_episode(episode_id)

    path_list = @scr.get_imgs(article[:url])
    if path_list.empty?
      raise "error: save images"
      exit
    end

    unless @clnt.create_images(episode_id, path_list)
      raise "error: create episode ##{episode_id} images"
    end

    unless @clnt.update_episode(episode_id, RETRIEVED)
      raise "error: update episode ##{episode_id} status => #{RETRIEVED}"
    end
  end

  def register_sentence episode_id
    images = @clnt.get_images(episode_id)

    pattern = {
      "！"=>"", "!"=>"", ","=>"", "."=>"", "。"=>"", "\n"=>"",
      "《"=>"", "》"=>"", "？" => "", "?"=>"", "~"=>"", "→"=>""
    }
    request = []
    images.each do |img|
      puts img
      if img["sentence"].nil?
        system("./cpp/preprocess.app #{img['path']}")
        desc = CloudVision.new.get_description("output.jpg")
        sentence = desc.gsub(/[#{pattern.keys.join}]/, pattern)
        puts sentence
        request << {"path" => img["path"], "sentence" => sentence}
      end
    end

    unless @clnt.update_images(request)
      exit 1
    end

    unless @clnt.update_episode(episode_id, REGISTERED)
      exit 1
    end
  end
end


job = Job.new
job.main
