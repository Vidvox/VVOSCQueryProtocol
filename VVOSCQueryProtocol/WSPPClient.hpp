#ifndef WSPPClient_hpp
#define WSPPClient_hpp

#include <stdio.h>
#include <string>
#include "WSPPQueryReply.hpp"

// The ASIO_STANDALONE define is necessary to use the standalone version of Asio.
// Remove if you are using Boost Asio.
#define ASIO_STANDALONE

#include <websocketpp/config/asio_no_tls.hpp>
#include <websocketpp/http/request.hpp>
#include <websocketpp/client.hpp>
#include <websocketpp/connection.hpp>
#include <websocketpp/common/thread.hpp>

using client_t = websocketpp::client<websocketpp::config::asio>;

using namespace websocketpp;
using namespace std;


class WSPPClient {
public:
	/*	this is the callback- this is the type of the block that gets executed every time the 
	websocket receives data.  it gets passed the raw string received over the websocket connection, 
	and it returns a query reply (to skip a reply, return a WSPPQueryReply(false) or WSPPQueryReply())			*/
	using WSCallback = std::function<const WSPPQueryReply (const std::string & inRawWSString)>;
	/*	this is the close websocket callback- this is the type of the block that gets called when 
	the server closes the connection to this client (or if the connection fails).  it doesn't get 
	passed any data- it's basically just a notification callback.			*/
	using CloseCallback = std::function<void(void)>;
	
private:
	lib::shared_ptr<lib::thread>		thread = nullptr;	//	the thread that the client uses to process data
	lib::shared_ptr<client_t>			client = nullptr;	//	the actual websocket++ client
	websocketpp::connection_hdl		clientConn;	//	the client connection (this class only maintains a single connection for the client)
	bool				connected = false;	//	whether or not this client is connected to a remote server
	bool				running = false;	//	whether or not this client has been started
	WSCallback			wsCallback = nullptr;
	CloseCallback		closeCallback = nullptr;

public:
	WSPPClient();
	~WSPPClient();
	
	//	the websocket callback is called in response to any data received from the server i'm connected to
	void set_websocket_callback(WSCallback inCallback);
	//	the close callback is called when i disconnect from the server i'm connected to
	void set_close_callback(CloseCallback inCallback);
	
	//	connects to the passed URI.  returns a true if successful, a false if unsuccessful for any reason or if already connected or if it hasn't been started yet
	bool connect(const string & inStringURI);
	//	disconnects from the currently-connected server
	void disconnect();
	//	returns a true if connected to a server, a false if not
	bool isConnected();
	
	//	sends the passed string to the server i'm connected to
	void send(const std::string & inStringToSend);


private:
	//	launches the client- spawns a thread, which is where the processing is done.
	void start();
	//	stops the client (calls 'disconnect()' first, then actually stops the client from running).  this returns execution from the thread that called 'start'.
	void stop();
	//	returns a true if running, a false if not
	bool isRunning();
};

#endif /* WSPPClient_hpp */
