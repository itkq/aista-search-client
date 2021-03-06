require 'mechanize'
require 'dotenv'

class Scraper
  INDEX_URL = 'http://aikatunews.livedoor.biz/archives/cat_252353.html'

  def initialize logger, img_dir='./img/'
    Dotenv.load
    @mech = Mechanize.new
    @mech.user_agent_alias = 'Mac Firefox'
    @logger = logger
    @dir = img_dir
    @thumb_dir = @dir + 'thumb/'
  end

  def get_article_by_episode ep
    page = 1
    while true
      articles = get_articles(page)
      if articles.empty?
        return nil
      end
      if articles.keys.include?(ep)
        return articles[ep]
      end

      page += 1
    end
  end

  def get_articles page=1
    page = @mech.get(INDEX_URL + "?p=#{page}")

    arr = page.search('div.article-header').map{|a|
      if a.css('.article-category > a').text.match('アイカツスターズ')
        matched = a.css('.article-title > a').text.match(/第(\d+)話[ 　]+(.+)$/)
        ep = matched[1].to_i
        title = matched[2]
        url = a.css('.article-title > a').attr('href').value
        [ep, {title: title, url: url}]
      end
    }.compact

    Hash[*arr.flatten]
  end

  def get_imgs url, thumb_flg=false
    @logger.info url
    page = @mech.get(url)
    resources = get_img_resources(page)

    ep = get_episode(page)
    @logger.info "get image from episode #{ep}"
    @logger.info "#{resources.size} images"
    format = "%03d.jpg"

    dirname = @dir + ("%03d" % ep) + "/"

    @logger.info dirname
    unless File.exists?(dirname)
      FileUtils.mkdir(dirname)
    end

    if thumb_flg
      thumb_dirname = @thumb_dir + ("%03d" % ep) + "/"
      unless File.exists?(thumb_dirname)
        FileUtils.mkdir_p(thumb_dirname)
        @logger.info "make thumb dir ##{ep}"
      end
    end

    succ = []
    resources.each_with_index do |_url, i|
      path = dirname + format % [i+1]
      if save_img(path, _url)
        if thumb_flg
          dst = thumb_dirname + format % [i+1]
          reduction(path, dst)
        end

        succ << path
      end
      sleep rand(5)+1
    end

    succ
  end

  def reduction src, dst
    img = Magick::Image.read(src).first
    img.scale(0.5).write(dst)
  end

  def get_episode page
    page.title.match(/第(\d+)話/)[1]
  end

  def get_img_resources page
    get_thumbnail_resources(page).map{|r|
      r.gsub(/-s\.jpg$/, ".jpg")
    }
  end

  def get_thumbnail_resources page
    body = page.search('div.article-body')
    body.css('img').map{|img|
      url = img.attr('src')
      if (!url.index('images-amazon'))
        url
      end
    }.compact
  end

  def save_img path, url
    begin
      @mech.get(url).save_as(path)
    rescue => e
      @logger.warn e.message
      return false
    end

    @logger.info "#{url} ==> finished"
    true
  end

end
