#require "http/web_socket"
require "http"
require "kemal"
require "logger"

require "./chromie/*"

module Chromie
  extend self
  unless ENV.has_key?("CHROMIE_CHROME_PORT_START") && ENV.has_key?("CHROMIE_CHROME_PORT_END")
    raise KeyError.new("CHROMIE_CHROME_PORT_START and CHROMIE_CHROME_PORT_END must be set")
  end


  class WebSocketHandler
    getter context
    def initialize(@context, &proc : WebSocket, Server::Context ->)
      handler.call(&proc)
    end
  end

  #ws "/" do |socket|
  #handler = HTTP::WebSocketHandler.new do |socket|
  handler = HTTP::WebSocketHandler.new do |socket, context|
    puts context
    id = context.request.resource.gsub("/?", "")
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    logger.formatter = ::Logger::Formatter.new do |severity, datetime, progname, message, io|
      io << "#{id}: #{message}"
    end

    begin
      port_range = ENV["CHROMIE_CHROME_PORT_START"].to_i..ENV["CHROMIE_CHROME_PORT_END"].to_i
      chrome_process = ChromeProcess.new(port_range, logger)
    rescue ex : ChromeProcessError
      logger.warn(ex.message)
      socket.close("Chrome process failed to start")
      next
    end
            
    #begin
      chrome_socket = HTTP::WebSocket.new(URI.parse(chrome_process.websocket_debugger_url))
      chrome_socket.on_message do |msg|
        socket.send(msg) unless socket.closed?
      end

      chrome_socket.on_close do |msg|
        logger.debug "chrome_socket#on_close"
        socket.close("closed") unless socket.closed?
        delay(5) { chrome_process.kill }
      end

      spawn do
        begin
          chrome_socket.run
        rescue
          logger.debug "Error in RUN"
          socket.close("closed") unless socket.closed?
          chrome_socket.close("closed") unless chrome_socket.closed?
          spawn do
            sleep 5
            chrome_process.kill
          end
        end
      end

      socket.on_message do |msg|
        if msg.includes?(%("method":"Browser.close"))
          logger.debug "Intercepted Browser.close, calling socket.close"
          socket.close("closed")
          chrome_socket.close("closed")
        else
          begin
            chrome_socket.send(msg) unless chrome_socket.closed?
          rescue ex
            logger.debug(ex.message)
            chrome_socket.close("closed") unless chrome_socket.closed?
            socket.close("closed") unless socket.closed?
            spawn do
              sleep 5
              chrome_process.kill
            end
            next
          end
        end
      end

      socket.on_close do |msg|
        logger.debug "socket#on_close"

        begin
          chrome_socket.close("closed") unless chrome_socket.closed?
        rescue ex
          logger.debug(ex.message)
          chrome_socket.close("closed") unless chrome_socket.closed?
          socket.close("closed") unless socket.closed?
          spawn do
            sleep 5
            chrome_process.kill
          end
          next
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

  # Kemal.run(port: 9333)
  server = HTTP::Server.new(handler)
  puts "Listening on http://0.0.0.0:9333"
  server.listen("0.0.0.0", 9333)
end
