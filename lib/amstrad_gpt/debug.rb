module AmstradGpt
  module Debug
    def debug(text)
      puts "[#{Time.current}] #{name}: #{text}" if text.present?
    end

    def name
      self.class.name.demodulize
    end
  end
end
