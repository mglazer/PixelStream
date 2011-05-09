#!/usr/bin/env ruby
#
#


require 'rubygems'
require 'mongo'
require 'bson'
require 'zmq'
require 'json'


LOG_PREFIX = "LOG "


class MongoLogger

	def initialize
		@connection = Mongo::Connection.new
		@db = @connection['pixel-logger-test']
		@collection = @db['pixel-logs']
		ensure_indicies
	end

	def log(pixel)
		puts "Logging: #{pixel}"
		@collection.insert(JSON.parse(pixel))
	end

	private

	def ensure_indicies
		@collection.ensure_index( [['coordinates', Mongo::GEO2D]] )
	end

end


class ZMQLogProcessor

	def initialize(logger)
		@logger = logger
		@zmq = ZMQ::Context.new
		@socket = @zmq.socket(ZMQ::SUB)
		@socket.connect( "tcp://localhost:5555" )
		@socket.setsockopt( ZMQ::SUBSCRIBE, LOG_PREFIX )
		puts "Connected to [tcp://localhost:5555]"
		@continue = true
	end

	def receive
		while @continue
			@logger.log(strip_prefix(@socket.recv))
		end
	end

	def strip_prefix(msg)
		msg[LOG_PREFIX.size..-1]
	end

	def stop
		@continue = false
	end
end


logger = MongoLogger.new
log_processor = ZMQLogProcessor.new(logger)

puts "Starting request handler thread"
t1 = Thread.new do
	log_processor.receive
end

Signal.trap("QUIT") do 
	puts "Stopping request handler"
	log_processor.stop
end

Signal.trap("TERM") do 
	puts "Stopping request handler"
	log_processor.stop
end

while true
	sleep(1)
end

