require "./src/chromie"

sleep 5

port_range = ENV["CHROMIE_CHROME_PORT_START"].to_i..ENV["CHROMIE_CHROME_PORT_END"].to_i

cnt = 0
loop do
  10.times do
    spawn do
      process = Chromie::ChromeProcessManager.launch(port_range)
      sleep 5
      process.kill
    end

  end

  cnt += 10
  puts ">>>>>>>>>>>>>>>>>> #{cnt} <<<<<<<<<<<<<<<<<<<<<<<<<<"
  sleep 5
end
