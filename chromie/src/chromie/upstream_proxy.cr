module Chromie
  class UpstreamProxy
    getter chrome_socket, socket

    delegate run, close, closed?, to: @socket

    def initialize(@socket : HTTP::WebSocket, @chrome_socket : HTTP::WebSocket)
      socket.on_message { |msg| on_message(msg) }
      socket.on_close { |msg| on_close(msg) }
    end

    def on_message(msg)
      if msg.includes?(%("method":"Browser.close"))
	logger.debug "Intercepted Browser.close, calling socket.close"
	socket.close("closed")
	chrome_socket.close("closed")
      else
	begin
	  chrome_socket.send(msg) unless chrome_socket.closed?
	rescue ex
	  logger.debug(ex.message)
	  chrome_socket.close("closed") unless chrome_socket.closed?
	  socket.close("closed") unless socket.closed?
	  # spawn do
	    # sleep 5
	    # chrome_process.kill
	  # end
	  #return
	end
      end
    end

    def on_close(msg)
      logger.debug "socket#on_close"

      begin
	chrome_socket.close("closed") unless chrome_socket.closed?
      rescue ex
	logger.debug(ex.message)
	chrome_socket.close("closed") unless chrome_socket.closed?
	socket.close("closed") unless socket.closed?
	# spawn do
	  # sleep 5
	  # chrome_process.kill
	# end
	# return
      end
    end
  end
end
