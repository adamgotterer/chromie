require "http/web_socket"
require "kemal"
require "logger"

require "./chromie/*"

module Chromie
  extend self
  SOCKETS = [] of HTTP::WebSocket

  ws "/" do |socket|
    begin
      chrome_process = ChromeProcess.new(port: 9222)
    rescue Timeout
      msg = "Chrome process failed to start"
      logger.warn(msg)
      socket.close(msg)
      next
    end

    chrome_socket = HTTP::WebSocket.new(URI.parse(chrome_process.websocket_debugger_url))
    chrome_proxy = WebSocketProxyHandler.new("Chrome", socket: chrome_socket, proxy_socket: socket) do |msg|
     chrome_process.kill
    end
    spawn { chrome_proxy.run }

    upstream_proxy = WebSocketProxyHandler.new("Everyurl", socket: socket, proxy_socket: chrome_socket)
    upstream_proxy.start_socket_monitor
  end

  puts "Listening on http://0.0.0.0:9333"
  Kemal.run(port: 9333)
end
