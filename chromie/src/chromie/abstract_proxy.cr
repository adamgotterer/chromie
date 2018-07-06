require "http/web_socket"

module Chromie
  abstract class AbstractProxy
    # Minutes to sleep before timeing out the socker
    SOCKET_TIMEOUT = ENV.fetch("SOCKET_TIMEOUT", "5").to_i * 60

    @socket : HTTP::WebSocket
    @upstream_socket : HTTP::WebSocket

    getter upstream_socket, socket
    delegate run, close, closed?, to: @socket

    def initialize(@socket, @upstream_socket)
      socket.on_message { |msg| on_message(msg) }
      socket.on_close { |msg| on_close(msg) }

      start_socket_timeout
    end

    #  This method will start a timeout counter based on SOCKET_TIMEOUT
    #  and will kill the socket if the SOCKET_TIMEOUT has been exceeded
    def start_socket_timeout
      spawn do
	timeout(SOCKET_TIMEOUT) do
	  break if closed?
	end
      rescue ex : TimeoutError
	logger.debug "Socket timeout of #{SOCKET_TIMEOUT / 60 } min exceeded. Closing socket."
	socket.close unless socket.closed?
	upstream_socket.close unless upstream_socket.closed?
	next
      end
    end

    def on_message(msg)
      begin
	upstream_socket.send(msg) unless upstream_socket.closed?
      rescue ex
	upstream_socket.close("closed") unless upstream_socket.closed?
	socket.close("closed") unless socket.closed?
      end
    end

    def on_close(msg)
      logger.debug "#{self.class}#on_close"
      upstream_socket.close("closed") unless upstream_socket.closed?
    end
  end
end
