module Chromie
  class WebSocketProxyHandler
    getter socket, proxy_socket, connected, logger

    @on_close_callback : Proc(String, Nil) | Nil

    # Seconds to sleep between socket checks
    MONITOR_TIMEOUT = 1
    
    # Number of heartbeat failures before the socket is considered closed
    HEARTBEAT_FAILURES = 3

    # Minutes to sleep before timeing out the socker
    SOCKET_TIMEOUT = ENV.fetch("SOCKET_TIMEOUT", "5").to_i * 60

    def initialize(@name : String, @socket : HTTP::WebSocket, @proxy_socket : HTTP::WebSocket, @logger : Logger, &on_close_block : String ->)
      @on_close_callback = on_close_block

      initialize_socket_handler
    end

    def initialize(@name, @socket : HTTP::WebSocket, @proxy_socket : HTTP::WebSocket, @logger : Logger)
      initialize_socket_handler
    end

    def connected?
      !socket.closed? && !proxy_socket.closed?
    end

    # Spawns a fiber that sends a socket.pong to check if the connection is
    #  still alive. We use a pong instead of a ping because we don't
    #  actually need a response and are just checking that the connection
    #  remains up. If it isn't up the pong will fail and raise an Exception
    #  which will be caught by the disconnect_handler.
    def start_socket_heartbeat
      spawn do
	failures = 0
	loop do
	  break if !connected?

	  begin
	    socket.pong
	  rescue
	    failures += 1
	    if failures >= 3
	      on_close
	      break
	    end
	  end

	  sleep MONITOR_TIMEOUT
	end
      end
    end

    #  This method will also start a timeout based on SOCKET_TIMEOUT
    #  and will kill the socket if the timeout has been exceeded
    def start_socket_timer
      spawn do
	timeout(SOCKET_TIMEOUT) do
	  break if !connected?
	end
      rescue ex : TimeoutError
	on_close
	next false
      end
    end

    def run
      spawn do
	disconnect_handler { socket.run }
	#socket.run
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
      # Intercept any Browser.close requests and handle it internally
      if msg.includes?(%("method":"Browser.close"))
	logger.debug "Intercepted Browser.close, calling socket.close"
	on_close
      else
	proxy_socket.send(msg)
      end
    end

    private def on_close(msg = "")
      logger.debug "#{@name}: on close called"

      begin
	#socket.close
      rescue Errno
      end

      begin
	# proxy_socket.close
      rescue Errno
      end

      if callback = @on_close_callback
	callback.call(msg)
      end
    end

    private def disconnect_handler
      begin
	yield
      rescue ex: Errno | IO::Error
	logger.debug "#{@name} disconnect handler called"
	logger.debug "#{@name}: #{ex.message}"
	on_close
	return false
      end
    end
  end
end
