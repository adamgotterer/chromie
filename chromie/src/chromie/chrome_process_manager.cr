module Chromie
  module ChromeProcessManager
    extend self

    # The ChromeProcess#launch method runs a timeout method that ensures the
    #  process has launched. Because we use a Mutex to reserve the port this causes
    #  a blocking process. The ChromeProcessReservation class was added to put
    #  a temp lock in place
    class ChromeProcessReservation
      getter port

      def initialize(@port : Int32)
      end
    end

    @@processes = [] of ChromeProcess | ChromeProcessReservation

    def launch(port_range : Range, logger : Logger)
      reservation = Mutex.new.synchronize do
	port = next_available_port(port_range)
	raise ChromeProcessError.new("No available port to bind on") unless port
	process_reservation = ChromeProcessReservation.new(port)
	register(process_reservation)
	process_reservation
      end

      begin
	chrome_process = ChromeProcess.new(port: reservation.port, logger: logger)
	Mutex.new.synchronize do
	  unregister(reservation)
	  register(chrome_process)
	end
      rescue ex
	Mutex.new.synchronize do
	  unregister(chrome_process) if chrome_process.is_a?(ChromeProcess)
	  unregister(reservation) if reservation.is_a?(ChromeProcessReservation)
	end
	raise ex
      end

      chrome_process
    end

    def register(process : ChromeProcess | ChromeProcessReservation)
      if process.is_a?(ChromeProcessReservation)
	logger.debug "Registering temporary hold on port #{process.port}"
      else
	logger.debug "Registering port #{process.port}"
      end

      Mutex.new.synchronize { @@processes << process }
    end

    def unregister(process : ChromeProcess | ChromeProcessReservation)
      if process.is_a?(ChromeProcessReservation)
	logger.debug "Freeing temporary reservation on port #{process.port}"
      else
	logger.debug "Freeing port #{process.port}"
      end

      Mutex.new.synchronize { @@processes.delete(process) }
    end

    def next_available_port(port_range : Range)
      port = 0
      Mutex.new.synchronize do
	active = active_ports
	puts "ACTIVE PORTS"
	puts active
	port = port_range.find { |x| !active.includes?(x) }
      end
      port
    end

    def active_ports
      @@processes.map { |x| x.port }
    end

    def processes
      @@processes
    end
  end
end
