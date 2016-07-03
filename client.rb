require 'dotenv'
require 'httpclient'
require 'json'

class Client

  def initialize
    Dotenv.load
    @base_uri = ENV['BASE_URI']
    @clnt = HTTPClient.new
  end

  def create_episode id, title
    endpoint = @base_uri + "/api/episode/create"
    data = {id: id, title: title}

    res = @clnt.post(endpoint, data)
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["status"] == "ok"
    else
      puts res
      false
    end
  end

  def update_episode id, status, title=""
    endpoint = @base_uri + "/api/episode/update"
    data = {id: id, title: title, status: status}

    res = @clnt.post(endpoint, data)
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["status"] == "ok"
    else
      puts res
      false
    end
  end

  def get_latest_episode
    endpoint = @base_uri + "/api/episode/latest"

    res = @clnt.get(endpoint)
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["episode"]
    else
      puts res
      nil
    end
  end

  def create_images id, path_list
    json = path_list.map{|p| {episode_id: id, path: p} }.to_json

    endpoint = @base_uri + "/api/image/create"
    res = @clnt.post(endpoint, json, 'Content-Type' => 'application/json')
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["count"] > 0
    else
      puts res
      false
    end
  end

  def update_images request
    json = JSON.generate(request)

    endpoint = @base_uri + "/api/image/update"
    res = @clnt.post(endpoint, json, 'Content-Type' => 'application/json')
    if res.status_code == 200
      body = JSON.parse(res.body)
      body["count"] > 0
    else
      puts res
      false
    end
  end

  def get_images id
    endpoint = @base_uri + "/api/images?episode_id=#{id}"
    res = @clnt.get(endpoint)

    if res.status_code == 200
      body = JSON.parse(res.body)
      body["images"]
    else
      puts res
      false
    end
  end

end
