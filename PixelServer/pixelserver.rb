#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sinatra'
require 'zmq'
require 'json'


def load_map_points(file)
	points = []
	puts "Loading mappoints from #{file}"
	open(file).each_line do |line|
		next if line.strip.empty?
		points << line.strip.split(" ")
	end
	puts "Finished loading #{points.size} map points from #{file}"
	points
end

context = ZMQ::Context.new(10)
responder = context.socket(ZMQ::PUB)
responder.bind( "tcp://*:5555" )

MAP_POINTS = load_map_points("mappoints-all.txt")


LOG_PREFIX  = "LOG "


helpers do
	def request_headers
		env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
	end
end


get '/pixel.gif' do 
	puts "Sending #{logged_request.inspect}"
	responder.send(LOG_PREFIX + logged_request, ZMQ::NOBLOCK)
	status 204 
	headers \
		"X-Server" => "Glazer Pixel Server"

end


def logged_request
	{
		'path_info' => request.path_info,
		'request_method' => request.request_method,
		'query_string' => request.query_string,
		'referrer' => request.referrer,
		'user_agent' => request.user_agent,
		'ip' => request.ip,
		'secure' => request.secure?,
		'forwarded' => request.forwarded?,
		'time'	=> Time.now.to_i,
		'coordinates' =>  MAP_POINTS[ rand( MAP_POINTS.size ) ]
	}.merge(request_headers).to_json
end
