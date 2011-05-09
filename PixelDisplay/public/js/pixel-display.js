function populateDataPoints(data) {
	for ( var i = 0, length = data.length; i < length; ++i ) {
		var current = data[i];
		$("#logbody").append("<tr><td>" + current['time'] + "</td><td>" + current['ip'] + "</td><td>" + current['user_agent'] + "</td><td><span class='longitude'>" + current['coordinates'][0] + "</span>,<span class='latitude'>" + current['coordinates'][1] + "</span></td></tr>");
		$("#globalmap").addPoint(current['coordinates']);

	};
}

(function( $ ) {
	$.fn.addPoint = function(point) {
		var lon = point[0];
		var lat = point[1];

		var theNewPoint = newPoint(lon, lat);
		this.append(theNewPoint);

		theNewPoint.animate({
			opacity: 1,
			height: '6px',
			width: '6px',
			'background-color': '#6699FF'
		}, 1500)
		.animate({
			height: '3px',
			width: '3px',
			'background-color': '#CC0033'
		}, 1500);
	};

	function newPoint(lon, lat) {
		console.log("Adding: " + lon + " " + lat);
		return $("<span class=\"pixel-dot\">&nbsp;</span>")
			.css({left: translateLon(lon), top: translateLat(lat), opacity: 0.25});
	}

	function translateLon(lon) {
		return (parseFloat(lon) + 150.);
	}

	function translateLat(lat) {
		return (parseFloat(lat) + 25.);
	}

})( jQuery );


function checkWebSocket(ws) {
	ws.send("CHECK");
	setTimeout(function() {
		checkWebSocket(ws);
	}, 1500);
}

$(document).ready(function() {
	$.get('/pixels', function(data) {
		$("#logbody").empty()
		populateDataPoints(data);
	});

	if ( !("WebSocket" in window) ) {
		alert("Sorry, your browser doesn't support WebSockets");
		return;
	}

	var ws = new WebSocket("ws://localhost:4569");

	ws.onopen = function() {
		console.log("Web socket has been opened");
	}

	ws.onmessage = function(evt) {
		console.log("Received event: ");
		console.log(evt);
		var data = JSON.parse( evt.data );
		
		console.log(data);
		populateDataPoints([data]);
	}

	setTimeout(function() {
		checkWebSocket(ws);
	}, 500);
});
