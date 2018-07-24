require "http"

cnt = 0
loop do
  10.times do
    spawn do
      client = HTTP::WebSocket.new(URI.parse("ws://127.0.0.1:9333"))
      client.send "ping"
      client.on_message do |str|
        puts str
        client.send "ping"
        sleep 1
        client.close
      end

      client.on_close do |str|
        puts "disconnected"
      end

      client.run
    end
  end

  cnt += 10
  puts ">>>>>>>>>>>>>>>>>> #{cnt} <<<<<<<<<<<<<<<<<<<<<<<<<<"
  sleep 5
end
