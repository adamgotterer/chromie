module Chromie
  class ChromeProxy
    getter upstream_socket, socket, chrome_process

    delegate run, close, closed?, to: @socket

    @chrome_process : ChromeProcess

    def initialize(@upstream_socket : HTTP::WebSocket, port_range : Range)
      @chrome_process = ChromeProcessManager.launch(port_range, logger)
      @socket = HTTP::WebSocket.new(URI.parse(chrome_process.websocket_debugger_url))

      socket.on_message { |msg| on_message(msg) }
      socket.on_close { |msg| on_close(msg) }
    end

    def on_message(msg)
      upstream_socket.send(msg) unless upstream_socket.closed?
    end

    def on_close(msg)
      logger.debug "chrome_socket#on_close"
      upstream_socket.close("closed") unless upstream_socket.closed?

      kill
    end

    def kill
      # Delay is used to give the socket a moment to close
      delay(5) { chrome_process.kill }
    end
  end
end
