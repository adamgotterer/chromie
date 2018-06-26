module Chromie
  class WebSocketProxyHandler
    getter socket, proxy_socket, connected

    @on_close_callback : Proc(String, Nil) | Nil
    @connected = true

    # Seconds to sleep between socket checks
    MONITOR_TIMEOUT = 5

    # Minutes to sleep before timeing out the socker
    SOCKET_TIMEOUT = ENV.fetch("SOCKET_TIMEOUT", "5").to_i * 60

    def initialize(@name : String, @socket : HTTP::WebSocket, @proxy_socket : HTTP::WebSocket, &close_block : String -> _)
      @on_close_callback = close_block

      initialize_socket_handler
    end

    def initialize(@name, @socket : HTTP::WebSocket, @proxy_socket : HTTP::WebSocket)
      initialize_socket_handler
    end

    # Spawns a fiber that sends a socket.pong to check if the connection is
    #  still alive. We use a pong instead of a ping because we don't
    #  actually need a response and are just checking that the connection
    #  remains up. If it isn't up the pong will fail and raise an Exception
    #  which will be caught by the disconnect_handler.
    #
    #  This method will also start a timeout based on SOCKET_TIMEOUT
    #  and will kill the socket if the timeout has been exceeded
    def start_socket_monitor
      spawn do
	timeout(SOCKET_TIMEOUT) do
	  break unless disconnect_handler { socket.pong } || connected

	  # We subtract 1 because "timeout" will sleep for 1 second
	  sleep MONITOR_TIMEOUT - 1
	end
      rescue ex : Timeout
	puts "#{@name}: rescued, closing"
	on_close
	next false
      end
    end

    def run
      spawn do
	disconnect_handler { socket.run }
      end
    end

    private def initialize_socket_handler
      socket.on_message do |msg|
	on_message(msg)
      end

      socket.on_close do |msg|
	on_close(msg)
      end
    end

    private def on_message(msg)
      proxy_socket.send(msg)
    end

    private def on_close(msg = "")
      return unless connected

      puts "#{@name}: on close called"
      @connected = false

      proxy_socket.close

      if callback = @on_close_callback
	callback.call(msg)
      end
    end

    private def disconnect_handler
      begin
	yield
      rescue Errno | IO::Error
	on_close
	return false
      end
    end
  end
end
