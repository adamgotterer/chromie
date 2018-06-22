require "http/server"

require "./chromie/*"

module Chromie
  SOCKETS = [] of HTTP::WebSocket

  handler = HTTP::WebSocketHandler.new do |socket|

    socket.on_message do |str|
      puts str
      socket.send("pong")

      sleep 1
    end

    socket.on_close do |str| # <===== Not called if the client unexpectedly hangs up
      puts "closed"
      puts str
    end

    spawn do
      loop do
        begin
          socket.pong
        rescue Errno | IO::Error
          puts "disconnected"
          break
        end
        sleep 2
      end
    end
  end

  server = HTTP::Server.new(handler)

  puts "Listening on http://0.0.0.0:9333"
  server.listen("0.0.0.0", 9333)
end
