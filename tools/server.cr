require "kemal"

handler = HTTP::WebSocketHandler.new do |session|
  puts session
  session.on_message do |str|
    puts str
    session.send("pong")
    sleep 1
  end

  session.on_close do |str|
    puts "closed"
    puts str
  end
end

server = HTTP::Server.new(handler)

puts "Listening on http://0.0.0.0:9333"
server.listen("0.0.0.0", 9333)


