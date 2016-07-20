require 'dotenv'
require 'logger'
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

  REQ_SIZE = 10

  def initialize
    Dotenv.load
    @logger = Logger.new('job.log')
    @scr = Scraper.new(@logger, ENV['APP_DIR'])
    @clnt = Client.new(@logger)
    @tw_clnt = TwitterClient.new(@logger)
  end

  def main
    case ARGV[0]
    when "daily"
      daily
    when "weekly"
      weekly
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
      if img['url'].nil?
        url = @tw_clnt.upload_image(img["path"])
        @logger.info "#{img["id"]} => #{url}"
        if url
          request << {
            "path"     => img["path"],
            "sentence" => img["sentence"],
            "url"      => url,
          }
        end
        sleep rand(5)+1
      end
    end

    unless @clnt.update_images(request)
      raise "error: update images"
    end
  end

  def weekly
    unless @clnt.ping
      raise "error: web server is not running"
    end

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
    @logger.info "target episode: #{episode_id}, status: #{status}"

    while status != REGISTERED
      @logger.info "[#{FUNCS[status]}]"
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
    path_list = @scr.get_imgs(article[:url], true)

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
      if img["sentence"].nil?
        magick_img = Magick::Image.read(img['path']).first
        magick_img.crop(0, 540, 1920, 1080).scale(0.5).write('output.jpg')
        desc = CloudVision.new.get_description("output.jpg")
        sentence = desc.gsub(/[#{pattern.keys.join}]/, pattern)
        sentence = sentence.each_char.to_a.delete_if{|c| c.ord > 39321}.join
        @logger.info "#{img['path']} => #{sentence}"

        if sentence.empty?
          FileUtils.rm(img['path'])
          FileUtils.rm(img['path'].sub('img', 'img/thumb'))
        else
          request << {"path" => img["path"], "sentence" => sentence}
        end
      end

      if request.size >= REQ_SIZE
        unless @clnt.update_images(request)
          raise "error: update images ##{episode_id}"
        end
        request = []
      end
    end

    unless request.empty? || @clnt.update_images(request)
      raise "error: update images ##{episode_id}"
    end

    unless @clnt.update_episode(episode_id, REGISTERED)
      raise "error: update episode ##{episode_id} status => #{REGISTERED}"
    end
  end

end


job = Job.new
job.main
