module Chromie
  class UpstreamProxy < AbstractProxy
    protected def chrome_socket
      upstream_socket
    end
  end
end
