require "http/client"
require "json"

module Chromie
  class ChromeProcess
    getter process, websocket_debugger_url, protocol_version, browser,
      port, output, pgid

    PROCESS_START_TIMEOUT = 10

    @port : Int32 = 0
    @process : Process
    @pgid : Int16 = 0
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

      cmd = "setsid /bin/google-chrome " + default_args.join(" ")

      puts cmd

      # Note: I'm not entirely sure why the Chrome process is writing
      #  the successful server creation to the error stream
      process = Process.new(cmd, shell: true, output: output, error: output)

      timeout(PROCESS_START_TIMEOUT) do
        break if output.to_s.includes?("DevTools listening on")
      rescue ex
        raise ChromeProcessError.new "Timed out while trying to launch a Chrome instance"
      end

      logger.debug "Launched chrome process with PID #{process.pid}"
      process
    end

    # This is a way to more accurately manage Chrome processes. When Chrome launches
    #  it spawns a buch of sub processes. Because of the Docker PID 1 issue every
    #  ends up with the same PGID. If you kill the Chrome PID then only the parent
    #  process exits and causes the sub processes to be orphaned. If you kill the PGID
    #  then every running instance of chrome is terminated. Above this code you will
    #  see tha the command to run chrome calls setsid which forces all the sub processes
    #  to run in a new session and share the same group id. Unfortunately the parent
    #  process still runs in PGID 1. So this code looks up the first child it finds
    #  based on the parent PID and grabs the group id that was assigned to it. Later
    #  on when we kill the processes we kill the parent id and then the group id.
    protected def get_pgid
      pgid_output = IO::Memory.new
      id = 0
      Process.run("pgrep -P #{process.pid}", shell: true, output: pgid_output)

      id = pgid_output.to_s.to_i16
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
