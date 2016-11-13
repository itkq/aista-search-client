require './lib/base'

class Episode < Base
  def initialize
    super
  end

  def create
    unless @clnt.ping
      raise "error: web server is not running"
    end

    ep = @clnt.get_latest_episode
    if ep && next_status(ep["status"]) != Status::CREATED
      puts "target: #{ep} ==> skip"
      return
    end

    unless ep # Initialize
      ep = {"id" => 1, "status" => Status::CREATED}
    else
      ep = {"id" => ep["id"]+1, "status" => Status::CREATED}
    end

    title = @crawler.get_episode_title(ep['id'])
    unless title
      puts "target: #{ep} ==> Not broadcasted yet. Skip."
    end

    puts "title: #{title}"
    unless @clnt.create_episode(ep["id"], title)
      raise "error: create episode ##{ep['id']} #{title}"
    end

    puts ' ==> created successfully'
  end
end
