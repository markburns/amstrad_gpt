require 'amstrad_gpt/text_response_handler'
require 'amstrad_gpt/image_response_handler'

module AmstradGpt
  class ResponseHandlerFactory
    def initialize(amstrad:)
      @amstrad = amstrad
    end

    def create_handler(reply)
      if reply.include?('{dalle:')
        ImageResponseHandler.new(reply: reply, amstrad: @amstrad)
      else
        TextResponseHandler.new(reply: reply, amstrad: @amstrad)
      end
    end
  end
end
