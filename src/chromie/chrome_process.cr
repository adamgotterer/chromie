require "http/client"
require "json"

module Chromie
  class ChromeProcess
    getter process, websocket_debugger_url, protocol_version, browser,
      port, output, pgid

    PROCESS_START_TIMEOUT = 10

    @port : Int32 = 0
    @process : Process
    @pgid : Int32 = 0
    @browser : String
    @protocol_version : String
    @websocket_debugger_url : String
    @output = IO::Memory.new

    delegate :terminated?, to: @process
    delegate :pid, to: @process

    def initialize(@port : Int32)
      @process = launch
      @pgid = get_pgid

      data = fetch_version_data
      @browser = data["Browser"]
      @protocol_version = data["Protocol-Version"]
      @websocket_debugger_url = data["webSocketDebuggerUrl"]
    end

    def launch
      logger.debug "Launching chrome process on port #{port}"

      default_args = Array{
        "--remote-debugging-port=#{port}",
        "--headless",
        "--no-sandbox",
        "--mute-audio",
        "--incognito",
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

      cmd = "/bin/google-chrome " + default_args.join(" ")

      # Note: I'm not entirely sure why the Chrome process is writing
      #  the successful server creation to the error stream
      process = Process.new(cmd, shell: true, output: output, error: output)

      begin
        timeout(PROCESS_START_TIMEOUT) do
          break if output.to_s.includes?("DevTools listening on")
        end
      rescue
        raise ChromeProcessError.new "Timed out while trying to launch Chrome instance: #{output.to_s}"
      end

      logger.debug "Launched chrome process with PID #{process.pid}"
      process
    end

    protected def get_pgid
      pgid_output = IO::Memory.new
      id = 0
      Process.run("pgrep -P #{process.pid}", shell: true, output: pgid_output)

      id = pgid_output.to_s.to_i32

      if id > 0
        logger.debug "Found chrome subprocess PGID #{id} for PID #{process.pid}"
        return id
      else
        raise ChromeProcessError.new "Subprocess PGID not found"
      end
    end

    def fetch_version_data
      res = HTTP::Client.get "http://localhost:#{port}/json/version"
      Hash(String, String).from_json(res.body)
    end

    def kill
      logger.debug "Killing chrome process with PID: #{process.pid}"
      process.kill

      logger.debug "Killing chrome sub processes with PGID: #{pgid}"
      Process.kill(Signal::TERM, pgid)

      ChromeProcessManager.unregister(self)
    end
  end
end
