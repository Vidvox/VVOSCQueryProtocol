#include "WSPPServer.hpp"
#include "VVOSCQueryStringUtilities.hpp"


WSPPServer::WSPPServer()	{
	cout << __PRETTY_FUNCTION__ << endl;
	
	//	reserve space for 100 simultaneous websocket connections
	server_conns.reserve(100);
	
	_initServer();
}
WSPPServer::~WSPPServer()	{
	cout << __PRETTY_FUNCTION__ << endl;
	stop();
	
	//	explicitly delete the server
	server = nullptr;
}


void WSPPServer::set_http_callback(HTTPCallback inCallback)	{
	httpCallback = inCallback;
	
	if (server != nullptr)	{
		//	pass a block to the websocketpp backend that will extract the URI from the connection nad pass it to the provided callback, which will return an WSPPQueryReply object that will be used to assemble a reply
		server->set_http_handler([=](connection_hdl hdl)	{
			lib::error_code			ec;
			server_t::connection_ptr		conn = server->get_con_from_hdl(hdl, ec);
			//	change some headers...
			conn->replace_header("Content-Type", "application/json; charset=utf-8");
			conn->replace_header("Connection", "close");
			//	pull the full URI out, this is what we're going to pass to the callback
			uri_ptr				uri = conn->get_uri();
			const string		&fullURI = uri->str();
			//	use the provided callback to get a reply for the URI
			const WSPPQueryReply		&tmpReply = (httpCallback==nullptr) ? WSPPQueryReply(400) : httpCallback(fullURI);
			//	use the WSPPQueryReply to reply to the http request
			try	{
				if (tmpReply.getReplyCode()<0)	{
					conn->set_body(std::move(tmpReply.getReplyString()));
					conn->set_status(websocketpp::http::status_code::ok);
				}
				else	{
					//conn->set_status(websocketpp::http::status_code::not_found);
					conn->set_status((http::status_code::value)tmpReply.getReplyCode());
				}
			}
			catch (const websocketpp::exception& e)	{
				cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
			}
			catch (const std::exception& e)	{
				cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
			}
			catch (...)	{
				cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << endl;
			}
		});
	}
}
void WSPPServer::set_websocket_callback(WSCallback inCallback)	{
	wsCallback = inCallback;
	
	if (server != nullptr)	{
		server->set_message_handler([&](connection_hdl hdl, server_t::message_ptr msg)	{
			//cout << __PRETTY_FUNCTION__ << endl;
			//cout << "\t\tmsg is " << msg->get_payload() << endl;
			
			//	use the provided callback to get a WSPPQueryReply for the message
			const WSPPQueryReply		&tmpReply = (wsCallback==nullptr) ? WSPPQueryReply(400) : wsCallback(msg->get_payload());
			
			//	use the WSPPQueryReply to reply to the message
			lib::error_code			ec;
			server_t::connection_ptr		conn = server->get_con_from_hdl(hdl, ec);
			//	if i'm not supposed to reply
			if (!tmpReply.getPerformReply())	{
				//	don't do anything, intentionally blank
			}
			//	else i'm supposed to perform some kind of reply
			else	{
				try	{
					//	if there's no error code, we're going to be sending a string in reply
					if (tmpReply.getReplyCode()<0)	{
						conn->set_body(std::move(tmpReply.getReplyString()));
						conn->set_status(websocketpp::http::status_code::ok);
					}
					//	else there's an error code of some kind- return it
					else	{
						conn->set_status((http::status_code::value)tmpReply.getReplyCode());
					}
				}
				catch (const websocketpp::exception& e)	{
					cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
				}
				catch (const std::exception& e)	{
					cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
				}
				catch (...)	{
					cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << endl;
				}
			}
		});
	}
}



void WSPPServer::_initServer()	{
	//	get the server set up
	if (server == nullptr)
		server = lib::make_shared<server_t>();
	lib::error_code			ec;
	server->init_asio(ec);
	server->set_reuse_addr(false);
	server->clear_access_channels(log::alevel::all);
	
	server->set_socket_init_handler([](connection_hdl handler, asio::ip::tcp::socket& s)	{
		asio::ip::tcp::no_delay			option(true);
		s.set_option(option);
	});
	
	//	the open handler should store the connection handle in the vector of connections
	server->set_open_handler([&](websocketpp::connection_hdl hdl)	{
		cout << __PRETTY_FUNCTION__ << endl;
		server_conns.push_back(hdl);
		
	});
	//	the close handler should remove the connection handle from the vector of connections
	server->set_close_handler([&](connection_hdl hdl)	{
		cout << __PRETTY_FUNCTION__ << endl;
		
		//std::shared_ptr<void>		hdlToFind = hdl.lock();
		lib::error_code			ec;
		std::shared_ptr<void>		hdlToFind = server->get_con_from_hdl(hdl, ec);
		int			tmpIndex = 0;
		for (std::weak_ptr<void> tmpHDL : server_conns)	{
			if (tmpHDL.lock() == hdlToFind)
			if (server->get_con_from_hdl(tmpHDL, ec) == hdlToFind)
			{
				cout << "\tfound conn to close at index " << tmpIndex << endl;
				server_conns.erase(server_conns.begin()+tmpIndex);
				break;
			}
			++tmpIndex;
		}
	});
	
	//	re-apply the http and ws callbacks
	if (httpCallback != nullptr)
		set_http_callback(httpCallback);
	if (wsCallback != nullptr)
		set_websocket_callback(wsCallback);
}
void WSPPServer::start(const int & inPort)	{
	cout << __PRETTY_FUNCTION__ << "... " << inPort << endl;
	//	if there's no server, make one
	if (server == nullptr)	{
		_initServer();
		if (server == nullptr)
			return;
	}
	
	//	if the server's already listening, bail
	if (server->is_listening())	{
		cout << "\terr: server already listening, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	
	bool		successful = false;
	int			tmpPort = max(inPort, 2345);
	while (!successful)	{
		try	{
			server->listen(asio::ip::tcp::v4(), tmpPort);
			successful = true;
		}
		catch (...)	{
			++tmpPort;
		}
	}
	
	lib::error_code		ec;
	server->start_accept(ec);
	//server->run();
	if (thread == nullptr)
		thread = lib::make_shared<lib::thread>(&server_t::run, &(*server));
}
void WSPPServer::stop()	{
	cout << __PRETTY_FUNCTION__ << endl;
	if (server==nullptr)	{
		cout << "\terr: no server, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	if (!server->is_listening())	{
		cout << "\terr: server already stopped, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	
	//	get a local copy of the server connections, then clear the server connections array
	std::vector<connection_hdl>		connsHdlsToClose(server_conns.begin(), server_conns.end());
	server_conns.clear();
	//	run through my open connections, closing each of them
	for (const auto & connHdlToClose : connsHdlsToClose)	{
		try	{
			server->close(connHdlToClose, websocketpp::close::status::going_away, std::string(""));
		}
		catch (const websocketpp::exception& e)	{
			cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
		}
		catch (const std::exception& e)	{
			cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
		}
		catch (...)	{
			cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << endl;
		}
	}
	
	try	{
		//	tell the server to stop listening
		server->stop_listening();
	}
	catch (const websocketpp::exception& e)	{
		cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
	}
	catch (const std::exception& e)	{
		cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
	}
	catch (...)	{
		cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << endl;
	}
	
	//	join the thread
	if (thread != nullptr)	{
		cout << "\tjoining the thread..." << endl;
		thread->join();
		thread = nullptr;
		cout << "\tdone joining the thread" << endl;
	}
	
	try	{
		//	delete the server
		server = nullptr;
	}
	catch (const websocketpp::exception& e)	{
		cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
	}
	catch (const std::exception& e)	{
		cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << ", " << e.what() << endl;
	}
	catch (...)	{
		cout << "\tERR: caught exception in " << __PRETTY_FUNCTION__ << endl;
	}
}
bool WSPPServer::isRunning()	{
	return (server==nullptr) ? false : server->is_listening();
}
int WSPPServer::getPort()	{
	//cout << __PRETTY_FUNCTION__ << endl;
	if (server == nullptr)
		return 0;
	lib::asio::error_code		ec;
	lib::asio::ip::tcp::endpoint		endpoint = server->get_local_endpoint(ec);
	int			returnMe = 0;
	returnMe = (int)endpoint.port();
	return returnMe;
}


void WSPPServer::sendStringToClients(const std::string & inStrToSend)	{
	cout << __PRETTY_FUNCTION__ << endl;
	if (server == nullptr)
		return;
	
	//	get a local copy of my connected servers, run through it, sending the buffer to each of them in turn
	std::vector<connection_hdl>		connsToSendTo(server_conns.begin(), server_conns.end());
	for (const auto & connToSendTo : connsToSendTo)	{
		lib::error_code			ec;
		server->send(connToSendTo, inStrToSend, frame::opcode::text, ec);
	}
}


