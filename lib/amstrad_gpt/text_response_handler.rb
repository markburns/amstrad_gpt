module AmstradGpt
  class TextResponseHandler
    include Debug

    def initialize(reply:, amstrad:)
      @reply = reply
      @amstrad = amstrad
    end

    def process_and_send
      debug "Sending to Amstrad: #{@reply}"
      @amstrad.send_to_amstrad("TXT:#{@reply}")
      debug "Sent to Amstrad: #{@reply}"
    end
  end
end
