require 'base64'
require 'json'
require 'uri'
require 'httpclient'
require 'dotenv'

class CloudVision
    def request(feature_type, image_file)
      image = open_image(image_file)
      base64_image = base64_encode(image)
      request_body = create_request_body(feature_type, base64_image)
      response = execute_cloud_vision(request_body)
      response
    end

    private
    def create_request_body(feature_type, base64_image)
      {
        requests: [{
          image: {
            content: base64_image
          },
          features: [
            {
              type: feature_type,
              maxResults: 10
            }
          ]
        }]
      }.to_json
    end

    def execute_cloud_vision(body)
      HTTPClient.new.post_content(api_url, body, 'Content-Type' => 'application/json')
    end

    def base64_encode(image)
      Base64.strict_encode64(image)
    end

    def open_image(image_file)
      if URI.extract(image_file).first.nil? then
        File.new(image_file, 'rb').read
      else
        HTTPClient.new.get_content(image_file)
      end
    end

    def api_url
      Dotenv.load
      "https://vision.googleapis.com/v1/images:annotate?key=#{ENV['GCP_API_KEY']}"
    end

end
