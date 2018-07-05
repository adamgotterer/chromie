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

    def handler(upstream_socket : HTTP::WebSocket, context : HTTP::Server::Context)
      puts context
      id = context.request.resource.gsub("/?", "")
      logger = Chromie.config.logger.dup
      logger.formatter = ::Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << "#{id}: #{message}"
      end

      begin
        port_range = ENV["CHROMIE_CHROME_PORT_START"].to_i..ENV["CHROMIE_CHROME_PORT_END"].to_i
        chrome_proxy = ChromeProxy.new(upstream_socket, port_range)
      rescue ex : ChromeProcessError
        logger.warn(ex.message)
        upstream_socket.close("Chrome process failed to start")
        return false
      end

      upstream_proxy = UpstreamProxy.new(socket: upstream_socket, chrome_socket: chrome_proxy.socket)
              
      #begin
        spawn do
          begin
            chrome_proxy.run
          rescue Errno | IO::Error
            logger.debug "Error in RUN"
            upstream_proxy.close("closed") unless upstream_proxy.closed?
            chrome_proxy.close("closed") unless chrome_proxy.closed?
            chrome_proxy.kill
          end
        end
        # chrome_proxy = WebSocketProxyHandler.new("Chrome", socket: chrome_socket, proxy_socket: socket, logger: logger) do |msg|
        #   chrome_process.kill
        # end
        # chrome_proxy.run
        # chrome_proxy.start_socket_timer

        # upstream_proxy = WebSocketProxyHandler.new("Everyurl", socket: socket, proxy_socket: chrome_socket, logger: logger)
        # upstream_proxy.start_socket_heartbeat
        # upstream_proxy.start_socket_timer
      #rescue ex
      #  chrome_process.kill
      #  raise ex
      #end
    end
  end

  def self.run
    port = ENV.fetch("CHROMIE_PORT", "9333")
    server = HTTP::Server.new(WebSocketHandler.new)
    puts "Listening on http://0.0.0.0:#{port}"
    server.listen("0.0.0.0", port.to_i32)
  end
end
