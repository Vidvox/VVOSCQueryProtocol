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
#include <mutex>

using config_t = websocketpp::config::asio;
using server_t = websocketpp::server<config_t>;

using namespace websocketpp;
using namespace std;


class WSPPServer {
public:
	/*	this is the HTTP callback- it gets passed the URI that was requested, and returns a 
	WSPPQueryReply object which will contain either a string or an error code			*/
	using HTTPCallback = std::function<const WSPPQueryReply (const std::string & inURI)>;
	
	/*	this is the websockets callback- it gets passed the raw string that was passed to the 
	socket, and doesn't return anything			*/
	using WSCallback = std::function<void (const std::string & inRawWSString)>;
	
	/*	this is the OSC callback- it gets passed the raw buffer that was passed to the socket.  
	it is not expected to return any kind of reply- it is up to the host software to parse this raw 
	data into an OSC packet, and then dispatch that packet to its local address space.				*/
	using OSCCallback = std::function<void (const void * inBuffer, const size_t & inBufferSize)>;
	
	/*	this is the LISTEN callback- it is called every time the server receives a JSON object with 
	"LISTEN" as the COMMAND over the websocket connection.  it returns a TRUE if the passed path is 
	valid and the server can start sending data from it to the client that requested to listen.  the 
	callback is passed the path the client wants to LISTEN to- during this callback, you should 
	configure your OSC address space to forward any OSC messages sent to the passed address to this 
	instance of the server using WSPPServer::sendOSCPacketToListeners().			*/
	using LISTENCallback = std::function<bool (const std::string & startListeningToMe)>;
	
	/*	this is the IGNORE callback- it is called every time the server receives a JSON object with 
	"IGNORE" as the COMMAND over the websocket connection.  the callback is passed the path the 
	client wants to stop LISTENng to- during this callback, you should configure your OSC address 
	space to stop forwarding any OSC messages sent to the passed address to this instance of the server.			*/
	using IGNORECallback = std::function<void (const std::string & stopListeningToMe)>;
	
private:
	lib::shared_ptr<lib::thread>	thread = nullptr;	//	the thread that the server runs on
	shared_ptr<server_t>			server = nullptr;	//	the actual websocket++ server
	mutex						connsLock;
	vector<connection_hdl>		server_conns = std::vector<connection_hdl>();	//	list of all currently-open websocket connections (so we can broadcast path changes)
	map<string,vector<connection_hdl>>	servers_by_listenAddr = map<string,vector<connection_hdl>>();	//	"key" is the OSC address being listened to, "value" is vector<connection_hdl>
	
	HTTPCallback		httpCallback = nullptr;	//	this callback lets you define how you want this class to respond to HTTP requests
	WSCallback			wsCallback = nullptr;	//	this callback lets you define how you want this class to respond to websocket messages it receives that have a frame::opcode::text opcode
	OSCCallback			oscCallback = nullptr;	//	this callback lets you define how you want this class to respond to websocket messages it receives that have a frame::opcode::binary opcode, which are assumed to be raw OSC packets send via the websocket's TCP connection
	LISTENCallback		listenCallback = nullptr;
	IGNORECallback		ignoreCallback = nullptr;
	
	void _initServer();
	void _performWSCallbackSetup();
	void _sendStringToClients(const std::string & inStrToSend);	//	this message will be propagated to all connected websocket clients
public:
	WSPPServer();
	~WSPPServer();
	
	//	the http callback is called every time the server receives an http request that isn't upgraded to a websocket connection.  this callback is how you implement the HTTP server side of the osc query proposal.
	void set_http_callback(HTTPCallback inCallback);
	//	the websocket callback is called every time the server receives frame::opcode::text data over one of its open websocket connections.
	void set_websocket_callback(WSCallback inCallback);
	//	the osc callback is called every time the server receives frame::opcode::binary data over one of its open websocket connections
	void set_osc_callback(OSCCallback inCallback);
	
	void set_listen_callback(LISTENCallback inCallback);
	void set_ignore_callback(IGNORECallback inCallback);
	
	//	execution will not be returned to the thread that calls this until the server is stopped!
	void start(const int & inPort=2345);
	void stop();
	bool isRunning();
	int getPort();
	
	//	these methods dispatch websocket messages to all connected clients
	void sendPathChangedToClients(const std::string & inChangedPath);
	void sendPathRenamedToClients(const std::string & inOldPath, const std::string & inNewPath);
	void sendPathRemovedToClients(const std::string & inRemovedPath);
	void sendPathAddedToClients(const std::string & inAddedPath);
	
	//void sendDataToClients(const void * bufferToSend, const int & sizeOfBuffer);
	//	call this method to send the passed OSC packet data to the clients that signed up to LISTEN to the passed path.
	void sendOSCPacketToListeners(const void * oscPacketToSend, const int & oscPacketSize, const char * listenPath);
};


#endif /* WPPServer_hpp */

