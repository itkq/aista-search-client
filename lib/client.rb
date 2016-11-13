require 'dotenv'
require 'httpclient'
require 'json'

class Client
  IMG_CNT = 100

  attr_reader :dir, :thumb_dir

  def initialize img_dir, logger, base_uri=nil, api_token=nil
    Dotenv.load
    @base_uri  = base_uri || ENV['BASE_URI']
    @token     = api_token || ENV['API_TOKEN']
    @clnt      = HTTPClient.new
    @logger    = logger
    @dir       = img_dir
    @thumb_dir = @dir + 'thumb/'
  end

  def ping
    endpoint = @base_uri + "/ping"
    begin
      res = @clnt.get(endpoint)
      res.status_code == 200
    rescue => e
      @logger.warn e.message
      false
    end
  end

  def create_episode id, title
    endpoint = @base_uri + "/api/episodes/?token=#{@token}"
    data = {id: id, title: title}

    res = @clnt.post(endpoint, data)
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["status"] == "ok"
    else
      @logger.warn res
      false
    end
  end

  def update_episode id, status, title=""
    endpoint = @base_uri + "/api/episodes/#{id}?token=#{@token}"
    data = {title: title, status: status}

    res = @clnt.put(endpoint, data)
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["status"] == "ok"
    else
      @logger.warn res
      false
    end
  end

  def get_latest_episode
    endpoint = @base_uri + "/api/episodes/?cnt=999&token=#{@token}"

    res = @clnt.get(endpoint)
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["episodes"].last
    else
      @logger.warn res
      nil
    end
  end

  def create_images id, path_list
    json = path_list.map{|p| {episode_id: id, path: p} }.to_json

    endpoint = @base_uri + "/api/images/?token=#{@token}"
    res = @clnt.post(endpoint, json, 'Content-Type' => 'application/json')
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["count"] > 0
    else
      @logger.warn res
      false
    end
  end

  def update_images request
    json = JSON.generate(request)

    endpoint = @base_uri + "/api/images/?token=#{@token}"
    res = @clnt.put(endpoint, json, 'Content-Type' => 'application/json')
    if res.status_code == 200
      body = JSON.parse(res.body)
      @logger.info "update #{body["count"]} images"
      body["count"] > 0
    else
      @logger.info json
      @logger.warn res
      false
    end
  end

  def delete_image id
    endpoint = @base_uri + "/api/images/#{id}?token=#{@token}"
    res = @clnt.delete(endpoint)
    if res.status_code == 200
      true
    else
      @logger.warn res
      nil
    end
  end

  def get_images id
    endpoint = @base_uri + "/api/images/?episode_id=#{id}&token=#{@token}"
    res = @clnt.get(endpoint)

    if res.status_code == 200
      body = JSON.parse(res.body)
      body["images"]
    else
      @logger.warn res
      false
    end
  end

  def get_upload_images
    endpoint = @base_uri + "/api/images/?cnt=#{IMG_CNT}&to_upload=true&token=#{@token}"
    res = @clnt.get(endpoint)

    if res.status_code == 200
      body = JSON.parse(res.body)
      body["images"]
    else
      @logger.warn res
      false
    end

  end
end
