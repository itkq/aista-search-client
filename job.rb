require 'dotenv'
require 'rmagick'
require './scraper'
require './client'
require './cloudvision'
require './twitter'

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
    @tw_clnt = TwitterClient.new
  end

  def main
    case ARGV[0]
    when "daily"
      daily
    when "weekley"
      weekley
    else
      puts "Usage: bundle exec ruby job.rb [type]"
      puts "  type : daily/weekly"
      exit 1
    end
  end

  def daily
    images = @clnt.get_upload_images
    unless images
      raise "error: get images to upload"
    end

    request = []
    images.each do |img|
      url = @tw_clnt.upload_image(ENV['IMG_RELATIVE_PATH'] + img["path"])
      puts url
      if url
        request << {
          "path"     => img["path"],
          "sentence" => img["sentence"],
          "url"      => url,
        }
      end
      sleep rand(5)+1
    end

    unless @clnt.update_images(request)
      raise "error: update images ##{episode_id}"
    end
  end

  def weekly
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
        img = Magick::Image.read(img['path'])
        img.crop(0, 540, 1920, 1080).scale(0.5).write('output.jpg')
        desc = CloudVision.new.get_description("output.jpg")
        sentence = desc.gsub(/[#{pattern.keys.join}]/, pattern)
        puts sentence
        request << {"path" => img["path"], "sentence" => sentence}
      end
    end

    unless @clnt.update_images(request)
      raise "error: update images ##{episode_id}"
    end

    unless @clnt.update_episode(episode_id, REGISTERED)
      raise "error: update episode ##{episode_id} status => #{REGISTERED}"
    end
  end

end


job = Job.new
job.main
