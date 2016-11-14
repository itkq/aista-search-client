require './lib/base'
require './lib/cloudvision'
require 'rmagick'


class Image < Base
  SPLIT_SIZE = 50

  def initialize
    super
  end

  def retrieve
    unless @clnt.ping
      raise "error: web server is not running"
    end

    ep = @clnt.get_latest_episode
    if ep && next_status(ep["status"]) != Status::RETRIEVED
      puts "target: #{ep} ==> skip"
      return
    end
    puts ep
    episode_id = ep["id"]

    path_list = @crawler.get_imgs(episode_id)
    if path_list.empty?
      raise "error: save images"
      exit
    end

    unless @clnt.create_images(episode_id, path_list)
      raise "error: create episode ##{episode_id} images"
    end

    unless @clnt.update_episode(episode_id, Status::RETRIEVED)
      raise "error: update episode ##{episode_id} status => #{Status::RETRIEVED}"
    end
  end

  def register
    unless @clnt.ping
      raise "error: web server is not running"
    end

    ep = @clnt.get_latest_episode
    if ep && next_status(ep["status"]) != Status::REGISTERED
      puts "target: #{ep}  ==> skip"
      return
    end
    puts ep
    episode_id = ep["id"]

    pattern = {
      "！"=>"", "!"=>"", ","=>"", "."=>"", "。"=>"", "\n"=>"",
      "《"=>"", "》"=>"", "？" => "", "?"=>"", "~"=>"", "→"=>""
    }
    request = []

    images = @clnt.get_images(episode_id).reverse
    images.each_slice(SPLIT_SIZE).to_a.each do |seq|
      seq.each do |img|
        if img["sentence"].nil?
          begin
            magick_img = Magick::Image.read(img['path']).first
            magick_img.crop(0, 540, 1920, 1080).scale(0.5).write('output.jpg')
            desc = CloudVision.new.get_description("output.jpg")
            sentence = desc.gsub(/[#{pattern.keys.join}]/, pattern)
            sentence = sentence.each_char.to_a.delete_if{|c| c.ord > 39321}.join
            @logger.info "#{img['path']} => #{sentence}"

            puts "sentence => '#{sentence}'"
            if sentence.empty?
              @clnt.delete_image(img['id'])
            else
              img['sentence'] = sentence
              request << img
            end
          rescue => e
            @logger.warn e.message
            @clnt.delete_image(img['id'])
          end
        end
      end

      if request.size > 0
        puts request
        unless @clnt.update_images(request)
          raise "error: update images ##{episode_id}"
        end
        request = []
      end
    end

    unless request.empty? || @clnt.update_images(request)
      raise "error: update images ##{episode_id}"
    end

    unless @clnt.update_episode(episode_id, Status::REGISTERED)
      raise "error: update episode ##{episode_id} status => #{Status::REGISTERED}"
    end
  end

  def create_thumbnail
    ep = @clnt.get_latest_episode
    if ep && next_status(ep["status"]) != Status::FINISHED
      puts "target: #{ep}  ==> skip"
      return
    end
    puts ep
    episode_id = ep["id"]

    f_ep = "%03d" % episode_id
    src = @clnt.dir+f_ep
    dst = @clnt.thumb_dir+f_ep

    unless File.exists?(dst)
      FileUtils.mkdir_p(dst)
    end

    files = `ls #{src}`.split("\n")
    files.each do |f|
      img = Magick::Image.read(src+'/'+f).first
      img.scale(0.3).write(dst+'/'+f)
      img.destroy!
      puts f
    end

    unless @clnt.update_episode(episode_id, Status::FINISHED)
      raise "error: update episode ##{episode_id} status => #{Status::FINISHED}"
    end
  end
end
