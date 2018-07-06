require "http"
require "logger"

require "./chromie/*"

module Chromie
  unless ENV.has_key?("CHROMIE_CHROME_PORT_START") && ENV.has_key?("CHROMIE_CHROME_PORT_END")
    ENV["CHROMIE_CHROME_PORT_START"] = "9222"
    ENV["CHROMIE_CHROME_PORT_END"] = "9322"
    logger.warn "CHROMIE_CHROME_PORT_START and CHROMIE_CHROME_PORT_END aren't 
      set, using default ports 9222-9322"
  end

  class WebSocketHandler < HTTP::WebSocketHandler
    def initialize
      super do |socket, context|
        handler(socket, context)
      end
    end

    def handler(client_socket : HTTP::WebSocket, context : HTTP::Server::Context)
      begin
        port_range = ENV["CHROMIE_CHROME_PORT_START"].to_i..ENV["CHROMIE_CHROME_PORT_END"].to_i
        chrome_proxy = ChromeProxy.new(client_socket, port_range)
      rescue ex : ChromeProcessError
        logger.warn(ex.message)
        client_socket.close("Chrome process failed to start")
        return false
      end

      upstream_proxy = UpstreamProxy.new(socket: client_socket, upstream_socket: chrome_proxy.socket)
              
      spawn do
        begin
          chrome_proxy.run
        rescue Errno | IO::Error
          logger.debug "chrome_proxy#run threw and exception. Closing sockets."
          upstream_proxy.close("closed") unless upstream_proxy.closed?
          chrome_proxy.close("closed") unless chrome_proxy.closed?
          chrome_proxy.kill
        end
      end
    end
  end

  def self.run
    port = ENV.fetch("CHROMIE_PORT", "9333")
    server = HTTP::Server.new(WebSocketHandler.new)
    puts "Listening on http://0.0.0.0:#{port}"
    server.listen("0.0.0.0", port.to_i32)
  end
end
