# cmd = "/usr/bin/google-chrome --headless --disable-gpu --disable-translate --disable-extensions --disable-background-networking --safebrowsing-disable-auto-update --enable-logging --disable-sync --metrics-recording-only --disable-default-apps --mute-audio --no-first-run --no-sandbox --incognito --remote-debugging-port=9222"

# x = Process.new(cmd, shell: true)#, output: output)

# puts x.pid
# puts x.terminated?
# x.kill
# sleep 2.seconds
# puts x.terminated?


require "http"

client = HTTP::WebSocket.new(URI.parse("ws://127.0.0.1:9333"))
client.send "ping"
client.on_message do |str|
  puts str
  client.send "ping"
  sleep 1
end

client.on_close do |str| # <==== Is called if the server unexpectedly hangs up
  puts "disconnected"
end
client.run
# client.stream(binary: false, frame_size: 1024) do |io|
  # puts io.to_s
# end
