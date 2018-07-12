module Chromie
  class Config
    INSTANCE = new

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
    end

    def logger
      @logger.not_nil!
    end

    def logger=(logger : Logger)
      @logger = logger
    end
  end

  def self.config
    yield Config::INSTANCE
  end

  def self.config
    Config::INSTANCE
  end
end
