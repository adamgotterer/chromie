require "http/client"

module Chromie
  class ChromeManager
    getter startup_timeout_seconds, max_processes, instances

    @process = [] of ChromeProcess

    def initialize(@max_processes : Int8 = 8, @startup_timeout_seconds : Int8 = 5)
    end
  end
end
