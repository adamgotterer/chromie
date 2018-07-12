module Chromie
  class UpstreamProxy < AbstractProxy
    protected def chrome_socket
      upstream_socket
    end

    def on_message(msg)
      if msg.includes?(%("method":"Browser.close"))
        logger.debug "Intercepted Browser.close, calling socket.close"
        socket.close("closed")
        chrome_socket.close("closed")
      else
        super msg
      end
    end
  end
end
