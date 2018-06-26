require "http/client"

module Chromie
  struct ChromeProcess
    getter process, websocket_debugger_url, protocol_version, browser, port, output

    @process : Process
    @browser : String
    @protocol_version : String
    @websocket_debugger_url : String
    @output = IO::Memory.new

    delegate :terminated?, to: @process
    delegate :pid, to: @process

    PROCESS_START_TIMEOUT = 10

    def initialize(@port : Int16)
      @process = launch_process
      data = fetch_version_data
      @browser = data["Browser"]
      @protocol_version = data["Protocol-Version"]
      @websocket_debugger_url = data["webSocketDebuggerUrl"]
    end

    def launch_process
      logger.debug "Launching chrome process"
      
      # --disable-background-networking 
      default_args = Array{
	"--headless ",
	"--no-sandbo",
	"--mute-audio",
	"--incognito",
	"--remote-debugging-port=#{port}",
	"--disable-background-timer-throttling",
	"--disable-breakpad",
	"--disable-client-side-phishing-detection",
	"--disable-default-apps",
	"--disable-dev-shm-usage",
	"--disable-extensions",
	"--disable-features=site-per-process",
	"--disable-hang-monitor",
	"--disable-popup-blocking",
	"--disable-prompt-on-repost",
	"--disable-sync",
	"--disable-translate",
	"--metrics-recording-only",
	"--no-first-run",
	"--safebrowsing-disable-auto-update"
      }

      cmd = "/usr/bin/google-chrome " + default_args.join(" ")

      # Note: I'm not entirely sure why the Chrome process is writting 
      #  the successful server creation to the error stream
      process = Process.new(cmd, shell: true, output: output, error: output)

      timeout(PROCESS_START_TIMEOUT) do
        break if output.to_s.includes?("DevTools listening on")
      end

      logger.debug "Launched chrome process with pid: #{process.pid}"
      process
    end

    def fetch_version_data
      res = HTTP::Client.get "http://localhost:9222/json/version"
      Hash(String, String).from_json(res.body)
    end

    def kill
      logger.debug "Killing chrome process with pid: #{process.pid}"
      Process.new("pkill -TERM -P #{process.pid}", shell: true)
      return
    end
  end
end
