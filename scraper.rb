require 'mechanize'
require 'dotenv'

class Scrape
  INDEX_URL = 'http://aikatunews.livedoor.biz/archives/cat_252353.html'

  def initialize
    Dotenv.load
    @mech = Mechanize.new
    @mech.user_agent_alias = 'Mac Firefox'
    @dir = 'img/'
  end

  def get_articles
    page = @mech.get(INDEX_URL)

    arr = page.search('div.article-header').map{|a|
      if a.css('.article-category > a').text.match('アイカツスターズ')
        ep = a.css('.article-title > a').text.match(/第(\d+)話/)[1].to_i
        url = a.css('.article-title > a').attr('href').value
        [ep, url]
      end
    }.compact

    Hash[*arr.flatten]
  end

  def get_imgs url, thumb_flg=false
    puts url
    page = @mech.get(url)
    if thumb_flg
      resources = get_thumbnail_resources(page)
    else
      resources = get_img_resources(page)
    end

    ep = get_episode(page)
    puts "get image from episode #{ep}"
    puts "#{resources.size} images"
    format = "%03d.jpg"

    dirname = @dir + ("%03d" % ep) + "/"
    puts dirname
    unless File.exists?(dirname)
      FileUtils.mkdir(dirname)
    end

    succ = []
    resources.each_with_index do |_url, i|
      path = dirname + format % [i + 1]
      if save_img(path, _url)
        succ << path
      end
      sleep(1)
    end

    succ
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
    print "saving #{url} ... "

    begin
      @mech.get(url).save_as(path)
    rescue => e
      puts e.message
      return false
    end

    puts 'finished'
    true
  end

end
