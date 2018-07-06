module Chromie
  class ChromeProxy < AbstractProxy
    getter chrome_process

    @chrome_process : ChromeProcess

    def initialize(@upstream_socket, port_range : Range)
      @chrome_process = ChromeProcessManager.launch(port_range)
      @socket = HTTP::WebSocket.new(URI.parse(chrome_process.websocket_debugger_url))

      super(@socket, @upstream_socket)
    end

    def on_close(msg)
      super

      kill
    end

    def kill
      # Delay is used to give the socket a moment to close
      delay(5) { chrome_process.kill }
    end
  end
end
