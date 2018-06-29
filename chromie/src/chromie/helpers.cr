class TimeoutError < Exception
end

def timeout(timeout : Int8 | Int16 | Int32)
  ticks = 0
  while ticks < timeout
	  yield
    sleep 1
  	ticks += 1
	end

  raise TimeoutError.new("Timed out after #{timeout} seconds")
end

def logger
  Chromie.config.logger
end
