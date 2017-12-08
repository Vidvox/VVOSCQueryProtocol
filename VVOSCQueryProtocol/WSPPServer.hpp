#ifndef WPPServer_hpp
#define WPPServer_hpp

#include <stdio.h>
#include <string>
#include "WSPPQueryReply.hpp"


/*		this class exists because i want to use websocket++ to implement the OSC query protocol's 
	backend in an objective-c framework.  i chose to do this as a pure c++ class so it can 
	potentially be reused to quickly and easily implement the query protocol on other platforms.			*/


// The ASIO_STANDALONE define is necessary to use the standalone version of Asio.
// Remove if you are using Boost Asio.
#define ASIO_STANDALONE

#include <websocketpp/config/asio_no_tls.hpp>
#include <websocketpp/http/request.hpp>
#include <websocketpp/server.hpp>
#include <websocketpp/connection.hpp>

using server_t = websocketpp::server<websocketpp::config::asio>;

using namespace websocketpp;
using namespace std;


class WSPPServer {
public:
	/*	this is the HTTP callback- it gets passed the URI that was requested, and returns a 
	WSPPQueryReply object which will contain either a string or an error code			*/
	using HTTPCallback = std::function<const WSPPQueryReply (const std::string & inURI)>;
	/*	this is the websockets callback- it gets passed the raw string that was passed to the 
	socket, and returns a WSPPQueryReply object which will contain either a string or an error code			*/
	using WSCallback = std::function<const WSPPQueryReply (const std::string & inRawWSString)>;
	
private:
	lib::shared_ptr<lib::thread>	thread = nullptr;	//	the thread that the server runs on
	shared_ptr<server_t>			server = nullptr;	//	the actual websocket++ server
	std::vector<connection_hdl>		server_conns = std::vector<connection_hdl>();	//	list of all currently-open websocket connections (so we can broadcast path changes)
	
	HTTPCallback		httpCallback = nullptr;
	WSCallback			wsCallback = nullptr;
	
	void _initServer();

public:
	WSPPServer();
	~WSPPServer();
	
	//	the http callback is called every time the server receives an http request that isn't upgraded to a websocket connection.  this callback is how you implement the HTTP server side of the osc query proposal.
	void set_http_callback(HTTPCallback inCallback);
	//	the websocket callback is called every time the server receives data over one of its open websocket connections.
	void set_websocket_callback(WSCallback inCallback);
	
	//	execution will not be returned to the thread that calls this until the server is stopped!
	void start(const int & inPort=2345);
	void stop();
	bool isRunning();
	int getPort();
	
	//	this message will be propagated to all connected websocket clients
	void sendStringToClients(const std::string & inStrToSend);
};


#endif /* WPPServer_hpp */

