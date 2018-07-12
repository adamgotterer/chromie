require "http"
require "logger"

require "kemal"
require "./chromie/*"

module Kemal
  def self.run(port : Int32?)
    self.run port do
      log "[#{config.env}] Chromie is ready to do it's thing at ws://#{config.host_binding}:#{config.port}"
    end
  end

  # TODO: Uncomment once kremal is bumped past 0.23.0 and remove the run overload
  # def self.display_startup_message(config, server)
    # addresses = server.addresses.map { |address| "ws://#{address}" }.join ", "
    # log "[#{config.env}] Chromie is ready to do it's thing at #{addresses}"
  # end
end

module Chromie
  Kemal.config.env = "production"
  Kemal.config.shutdown_message = false

  unless ENV.has_key?("CHROMIE_CHROME_PORT_START") && ENV.has_key?("CHROMIE_CHROME_PORT_END")
    ENV["CHROMIE_CHROME_PORT_START"] = "9222"
    ENV["CHROMIE_CHROME_PORT_END"] = "9322"
    logger.warn "CHROMIE_CHROME_PORT_START and CHROMIE_CHROME_PORT_END aren't
      set, using default ports 9222-9322"
  end

  ws "/browser" do |client_socket|
    begin
      port_range = ENV["CHROMIE_CHROME_PORT_START"].to_i..ENV["CHROMIE_CHROME_PORT_END"].to_i
      chrome_proxy = ChromeProxy.new(client_socket, port_range)
    rescue ex : ChromeProcessError
      logger.warn(ex.message)
      client_socket.close("Chrome process failed to start")
      next false
    end

    upstream_proxy = UpstreamProxy.new(socket: client_socket, upstream_socket: chrome_proxy.socket)

    spawn do
      begin
        chrome_proxy.run
      rescue Errno | IO::Error
        logger.debug "chrome_proxy#run threw and exception. Closing sockets."
        upstream_proxy.close("closed") unless upstream_proxy.closed?
        chrome_proxy.close("closed") unless chrome_proxy.closed?
        chrome_proxy.kill
      end
    end
  end

  get "/health" do
    "ok"
  end

  class RouteHandler
    include HTTP::Handler

    def call(context : HTTP::Server::Context)
      context.request.inspect
    end
  end

  def self.run
    port = ENV.fetch("CHROMIE_PORT", "9333")
    Kemal.run(port.to_i32)
  end
end
