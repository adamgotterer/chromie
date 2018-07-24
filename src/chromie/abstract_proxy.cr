require "http/web_socket"

module Chromie
  abstract class AbstractProxy
    # Minutes to sleep before timeing out the socker
    SOCKET_TIMEOUT = ENV.fetch("SOCKET_TIMEOUT", "5").to_i * 60
    HEARTBEAT_INTERVAL = 10

    @socket : HTTP::WebSocket
    @upstream_socket : HTTP::WebSocket

    getter upstream_socket, socket
      delegate run, close, closed?, to: @socket

    def initialize(@socket, @upstream_socket)
      socket.on_message { |msg| on_message(msg) }

      start_socket_timeout
      start_socket_heartbeat
    end

    # Starts a timeout counter based on SOCKET_TIMEOUT and will
    #   kill the socket if the SOCKET_TIMEOUT has been exceeded
    def start_socket_timeout
      spawn do
        timeout(SOCKET_TIMEOUT) do
          break if closed?
        end
      rescue ex : TimeoutError
        logger.debug "Socket timeout of #{SOCKET_TIMEOUT} seconds exceeded. Closing socket."
        close_sockets
        next
      end
    end

    def start_socket_heartbeat
      spawn do
        loop do
          sleep HEARTBEAT_INTERVAL
          logger.debug("Heartbeat: #{socket.closed?}")

          begin
            socket.ping
          rescue Errno | IO::Error
          end

          break if socket.closed?
        end

        next
      end
    end

    def close_sockets
      (socket.close("closed") unless socket.closed?) rescue Errno
      (upstream_socket.close("closed") unless upstream_socket.closed?) rescue Errno
    end

    def on_message(msg)
      begin
        upstream_socket.send(msg) unless upstream_socket.closed?
      rescue Errno | IO::Error
      end
    end
  end
end
