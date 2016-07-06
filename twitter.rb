require 'twitter'
require 'dotenv'

class TwitterClient
  def initialize logger
    @clnt = new_client
  end

  def upload_image path
    res = nil
    begin
      open(path) do |img|
        res = @clnt.update_with_media('', img)
      end
      return res.text
    rescue => e
      @logger.warn e.message
      return nil
    end
  end

  private
  def new_client
    Dotenv.load
    rest_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['CONSUMER_KEY']
      config.consumer_secret     = ENV['CONSUMER_SECRET']
      config.access_token        = ENV['ACCESS_TOKEN']
      config.access_token_secret = ENV['ACCESS_SECRET']
    end

    rest_client
  end
end
