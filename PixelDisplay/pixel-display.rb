#!/usr/bin/env ruby
#
#


require 'rubygems'
require 'sinatra'
require 'mongo'
require 'bson'
require 'json'
require 'haml'

require 'em-websocket'
require 'zmq'


connection = Mongo::Connection.new
db = connection['pixel-logger-test']
collection = db['pixel-logs']

if collection.nil?
	puts "Could not make connection to [pixel-logs] in [pixel-logger-test]"
	exit 1
end

emfork = Process.fork do

	LOG_PREFIX = "LOG "
	def strip_prefix( msg )
		puts "Sending #{msg}"
		msg[LOG_PREFIX.size..-1]
	end

	@sockets = []


	EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 4569) do |ws|
		ws.onopen do
			puts "Opening web socket"
			@sockets << ws
			zmq = ZMQ::Context.new(1)
			@socket = zmq.socket(ZMQ::SUB)
			@socket.connect( "tcp://localhost:5555" )
			@socket.setsockopt( ZMQ::SUBSCRIBE, LOG_PREFIX )

			puts "Finished opening web socket"
		end

		ws.onmessage do |mess|
			while (!( msg = @socket.recv( ZMQ::NOBLOCK ) ).nil? ) 
				ws.send( strip_prefix( msg ) )
			end
		end

		ws.onclose do
			@socket.close
			@sockets.delete @socket
		end
	end
end


get '/' do
	haml :index
end


get '/pixels' do
	[201, 
	 {'Content-Type' => 'application/json'},
	 collection.find.map { |log| log }.to_json]
end





