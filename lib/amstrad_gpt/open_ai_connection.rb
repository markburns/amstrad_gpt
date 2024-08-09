require 'faraday'

module AmstradGpt
  module OpenAiConnection
    def self.image(prompt:, size:, api_key:)
      response = post(
        url: 'https://api.openai.com/v1/images/generations',
        api_key:,
        body: {
          prompt:,
          n: 1,
          size:,
          response_format: 'url'
        }
      )

      response['data'][0]['url']
    end

    def self.post(body:, api_key:, url:)
      connection = self.for(url:, api_key:)

      response = connection.post do |req|
        req.body = body.to_json
      end

      JSON.parse(response.body).with_indifferent_access
    end

    def self.for(api_key:, url:)
      Faraday.new(url:) do |faraday|
        faraday.headers['Content-Type'] = 'application/json'
        faraday.headers['Authorization'] = "Bearer #{api_key}"
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
