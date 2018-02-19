#include "WSPPServer.hpp"
#include "VVOSCQueryStringUtilities.hpp"
#include "rapidjson/document.h"
//#include <websocketpp/connection.hpp>


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
	
	_performWSCallbackSetup();
}
void WSPPServer::set_osc_callback(OSCCallback inCallback)	{
	oscCallback = inCallback;
	
	_performWSCallbackSetup();
}
void WSPPServer::set_listen_callback(LISTENCallback inCallback)	{
	listenCallback = inCallback;
}
void WSPPServer::set_ignore_callback(IGNORECallback inCallback)	{
	ignoreCallback = inCallback;
}
void WSPPServer::_performWSCallbackSetup()	{
	if (server != nullptr)	{
		server->set_message_handler([&](connection_hdl hdl, server_t::message_ptr msg)	{
			cout << __PRETTY_FUNCTION__ << endl;
			//cout << "\t\tmsg is " << msg->get_payload() << endl;
			
			//WSPPQueryReply			tmpReply;
			
			switch (msg->get_opcode())	{
			case frame::opcode::text:
				{
					rapidjson::Document		tmpJSON;
					tmpJSON.Parse(msg->get_payload().c_str());
					if (tmpJSON.IsObject())	{
						if (tmpJSON.HasMember("COMMAND") && tmpJSON.HasMember("DATA") && tmpJSON["COMMAND"].IsString())	{
							const char		*tmpCmd = tmpJSON["COMMAND"].GetString();
							if (!strcmp(tmpCmd, "LISTEN") && tmpJSON["DATA"].IsString())	{
								//cout << "\t\tLISTEN received for " << tmpJSON["DATA"].GetString() << endl;
								
								//	get the address that we're being told to listen to
								string		tmpAddress = string(tmpJSON["DATA"].GetString());
								
								lock_guard<mutex>		lock(connsLock);
								
								//	find the entry that corresponds to the address the client wants to LISTEN to!
								auto		addressIter = servers_by_listenAddr.find(tmpAddress);
								//	if there aren't any servers listening to the address, make an array to store servers listening to the address
								if (addressIter == servers_by_listenAddr.end())	{
									servers_by_listenAddr.emplace(std::make_pair(tmpAddress, std::vector<connection_hdl>()));
									//servers_by_listenAddr[tmpAddress] = std::vector<connection_hdl>();
									addressIter = servers_by_listenAddr.find(tmpAddress);
								}
								
								//	...at this point i have an iterator pointing at an entry in the map that is currently registered to LISTEN to this address.  the entry's value is a vector of connection_hdls.
								
								//	get the vector from the iterator- run through its contents, looking for a match to the current connection
								vector<connection_hdl>		&listeningConns = addressIter->second;
								void						*currentConn = hdl.lock().get();
								bool						alreadyListening = false;
								for (const auto & tmpConn : listeningConns)	{
									if (tmpConn.lock().get() == currentConn)	{
										alreadyListening = true;
										break;
									}
								}
								//	if i'm not already listening to this connection...
								if (!alreadyListening)	{
									
									//	call the listen callback- this lets the delegate set up to listen, and determines if we should actually listen to the address (if it doesn't exist the delegate can prevent us from listening)
									bool				delegateSaysOKToListen = false;
									if (listenCallback != nullptr)
										delegateSaysOKToListen = listenCallback(tmpAddress);
									
									//	if the listen callback indicates that it's still okay to listen...
									if (delegateSaysOKToListen)	{
										//	add the connection to the vector!
										listeningConns.push_back(hdl);
									}
								}
								
								//tmpReply = WSPPQueryReply(false);
							}
							else if (!strcmp(tmpCmd, "IGNORE") && tmpJSON["DATA"].IsString())	{
								//cout << "\t\tIGNORE received for " << tmpJSON["DATA"].GetString() << endl;
								
								//	find the entry that corresponds to the address the client wants to IGNORE!
								string		tmpAddress = string(tmpJSON["DATA"].GetString());
								{
									lock_guard<mutex>		lock(connsLock);
									auto		addressIter = servers_by_listenAddr.find(tmpAddress);
									//	only proceed if there's a valid iterator...
									if (addressIter != servers_by_listenAddr.end())	{
										//	...at this point i have an iterator pointing at an entry in the map that corresponds to the address the client wants to IGNORE
									
										//	get the vector from the iterator- run through its contents, looking for a match to the current connection, delete it when you find it
										vector<connection_hdl>		&listeningConns = addressIter->second;
										void			*currentConn = hdl.lock().get();
										int				tmpIndex = 0;
										for (const auto & tmpConn : listeningConns)	{
											if (tmpConn.lock().get() == currentConn)	{
												//cout << "\t\tremoving listener!\n";
												listeningConns.erase(listeningConns.begin() + tmpIndex);
												break;
											}
											++tmpIndex;
										}
										//	if the vector is now empty- if nothing is listening to this address- then we should remove it entirely
										if (listeningConns.size() == 0)
											servers_by_listenAddr.erase(addressIter);
									}
								}
								
								//	call the ignore callback
								if (ignoreCallback != nullptr)
									ignoreCallback(tmpAddress);
								//tmpReply = WSPPQueryReply(false);
							}
							else	{
								//tmpReply = (wsCallback == nullptr) ? WSPPQueryReply(false) : wsCallback(msg->get_payload());
								wsCallback(msg->get_payload());
							}
						}
						//	else the COMMAND/DATA structure of this JSON object isn't valid- maybe something's missing, maybe COMMAND isn't a string, etc.
						else	{
							wsCallback(msg->get_payload());
						}
					}
					//	else the JSON object isn't an object
					else	{
						//	intentionally blank, do nothing
					}
				}
				break;
			case frame::opcode::binary:
				if (oscCallback != nullptr)	{
					//	this is how you access the raw binary data from the payload
					const std::string		&tmpString = msg->get_payload();
					oscCallback((void*)tmpString.data(), tmpString.length());
				}
				break;
			default:
				//tmpReply = WSPPQueryReply(false);
				break;
			}
			/*
			//	use the provided callback to get a WSPPQueryReply for the message
			const WSPPQueryReply		&tmpReply = (wsCallback==nullptr) ? WSPPQueryReply(400) : wsCallback(msg->get_payload());
			*/
			
			
			/*
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
			*/
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
		//cout << __PRETTY_FUNCTION__ << endl;
		asio::ip::tcp::no_delay			option(true);
		s.set_option(option);
	});
	
	//	the open handler should store the connection handle in the vector of connections
	server->set_open_handler([&](websocketpp::connection_hdl hdl)	{
		//cout << __PRETTY_FUNCTION__ << endl;
		lock_guard<mutex>		lock(connsLock);
		server_conns.push_back(hdl);
		
	});
	//	the close handler should remove the connection handle from the vector of connections
	server->set_close_handler([&](connection_hdl hdl)	{
		//cout << __PRETTY_FUNCTION__ << endl;
		
		lock_guard<mutex>		lock(connsLock);
		
		//cout << "\tchecking websocket conns...\n";
		//std::shared_ptr<void>		hdlToFind = hdl.lock();
		lib::error_code			ec;
		//	the hdl we were passed is a weak ref, if we want to compare it we need to upgrade it to a shared ptr
		//std::shared_ptr<void>		hdlToFind = server->get_con_from_hdl(hdl, ec);
		std::shared_ptr<connection<config_t>>		hdlToFind = server->get_con_from_hdl(hdl, ec);
		int			tmpIndex = 0;
		for (const std::weak_ptr<void> & tmpHDL : server_conns)	{
			//if (tmpHDL.lock() == hdlToFind)
			if (server->get_con_from_hdl(tmpHDL, ec) == hdlToFind) {
				//cout << "\t\tfound conn to close at index " << tmpIndex << endl;
				server_conns.erase(server_conns.begin()+tmpIndex);
				break;
			}
			++tmpIndex;
		}
		
		//cout << "\tchecking listen conns...\n";
		//	run through each entry in 'servers_by_listenAddr' (each entry is an address:connection array pair)
		for (std::map<string,vector<connection_hdl>>::iterator addrServerIt=servers_by_listenAddr.begin(); addrServerIt!=servers_by_listenAddr.end(); )	{
			//	run through each connection in this entry
			vector<connection_hdl>			&serverConns = addrServerIt->second;
			for (std::vector<connection_hdl>::iterator serverConnIt=serverConns.begin(); serverConnIt!=serverConns.end(); )	{
				//	if this connection matches the server that's closing
				if (server->get_con_from_hdl(*serverConnIt, ec) == hdlToFind)	{
					//cout << "\t\tdeleting conn " << hdlToFind->get_host() << "." << hdlToFind->get_port() << " at address " << addrServerIt->first << endl;
					//	remove the connection from this entry's array of connections
					serverConnIt = serverConns.erase(serverConnIt);
					//	if this entry's array of connections is now empty
					if (serverConns.size() == 0)	{
						//cout << "\t\tdeleting entry " << addrServerIt->first << endl;
						//	remove this entry
						addrServerIt = servers_by_listenAddr.erase(addrServerIt);
						break;
					}
					//	else there are connections in this entry- we want to continue checking them
					else	{
						//	intentionally blank (serverConnIt was incremented when we erased the entry)
					}
					
				}
				//	else this connection doesn't match the server that's closing- check the next
				else
					++serverConnIt;
				
				//	increment the addrServerIt here when we've finished running through the serverConns
				if (serverConnIt == serverConns.end())	{
					++addrServerIt;
					break;
				}
				
			}
			//++addrServerIt;	//	can't increment this here!
			
		}
		
		/*
		cout << "\tafter cleanup...\n";
		cout << "\tconns are:\n";
		for (auto tmpHDL : server_conns)	{
			auto		upgradedHdl = server->get_con_from_hdl(tmpHDL, ec);
			cout << "\t\t" << upgradedHdl->get_host() << "." << upgradedHdl->get_port() << endl;
		}
		cout << "\tlisten by addr map is:\n";
		for (auto addrServerIt : servers_by_listenAddr)	{
			cout << "\t\t" << addrServerIt.first << ":";
			for (auto serverConnIt : addrServerIt.second)	{
				auto		upgradedServerConn = server->get_con_from_hdl(serverConnIt, ec);
				cout << "  " << upgradedServerConn->get_host() << "." << upgradedServerConn->get_port();
			}
			cout << endl;
		}
		*/
		
	});
	
	//	re-apply the http and ws callbacks
	if (httpCallback != nullptr)
		set_http_callback(httpCallback);
	if (wsCallback != nullptr)
		set_websocket_callback(wsCallback);
}
void WSPPServer::start(const int & inPort)	{
	//cout << __PRETTY_FUNCTION__ << "... " << inPort << endl;
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
	int			tmpPort = max(inPort, 80);
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
	//cout << __PRETTY_FUNCTION__ << endl;
	if (server==nullptr)	{
		cout << "\terr: no server, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	if (!server->is_listening())	{
		cout << "\terr: server already stopped, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	
	//	get a local copy of the server connections, then clear the server connections array
	connsLock.lock();
	std::vector<connection_hdl>		connsHdlsToClose(server_conns.begin(), server_conns.end());
	server_conns.clear();
	connsLock.unlock();
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
		//cout << "\tjoining the thread..." << endl;
		thread->join();
		thread = nullptr;
		//cout << "\tdone joining the thread" << endl;
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


void WSPPServer::_sendStringToClients(const std::string & inStrToSend)	{
	//cout << __PRETTY_FUNCTION__ << endl;
	if (server == nullptr)
		return;
	
	//	get a local copy of my connected servers, run through it, sending the buffer to each of them in turn
	connsLock.lock();
	std::vector<connection_hdl>		connsToSendTo(server_conns.begin(), server_conns.end());
	connsLock.unlock();
	for (const auto & connToSendTo : connsToSendTo)	{
		lib::error_code			ec;
		server->send(connToSendTo, inStrToSend, frame::opcode::text, ec);
	}
}
void WSPPServer::sendPathChangedToClients(const std::string & inChangedPath)	{
	_sendStringToClients(FmtString("{ \"COMMAND\": \"PATH_CHANGED\", \"DATA\": \"%s\" }",inChangedPath.c_str()));
}
void WSPPServer::sendPathRenamedToClients(const std::string & inOldPath, const std::string & inNewPath)	{
	//cout << __PRETTY_FUNCTION__ << endl;
	{
		lock_guard<mutex>		lock(connsLock);
		vector<std::string>		keysToUpdate = vector<std::string>();
		//	run through the map for servers by OSC listen address
		for (const auto & addressMapIt : servers_by_listenAddr)	{
			const std::string		&tmpKey = addressMapIt.first;
			//	if this address contains the old path then it's going to be affected- stick the string in an array
			size_t				foundIndex = tmpKey.find(inOldPath);
			if (foundIndex == 0)	{
				//cout << "\t\tkey " << tmpKey << " is a match for the old path " << inOldPath << endl;
				keysToUpdate.push_back(tmpKey);
			}
		}
		//	run through the array of OSC addresses that are affected by the rename op
		for (const auto & keyToUpdate : keysToUpdate)	{
			//	get the vector of c onnections stored in the map at the old string
			vector<connection_hdl>		tmpConns = servers_by_listenAddr[keyToUpdate];
			//	figure out the new string
			std::string			newKey = std::string(keyToUpdate);
			newKey.replace(0, inOldPath.length(), inNewPath);
			//cout << "\t\told key is " << keyToUpdate << ", new key is " << newKey << endl;
			//	store the vector at the new key, then clear out the val at the old key!
			servers_by_listenAddr[newKey] = tmpConns;
			servers_by_listenAddr.erase(keyToUpdate);
		}
	}
	/*
	int			tmpIndex = 0;
	for (const auto & tmpIt : servers_by_listenAddr)	{
		cout << "\t\titerator index " << tmpIndex << ", key is " << tmpIt.first << ", vec has " << tmpIt.second.size() << " entries" << endl;
		++tmpIndex;
	}
	*/
	//	now actually inform the clients that the path has been renamed
	_sendStringToClients(FmtString("{ \"COMMAND\": \"PATH_RENAMED\", \"DATA\": { \"OLD\": \"%s\", \"NEW\": \"%s\" } }",inOldPath.c_str(),inNewPath.c_str()));
}
void WSPPServer::sendPathRemovedToClients(const std::string & inRemovedPath)	{
	_sendStringToClients(FmtString("{ \"COMMAND\": \"PATH_REMOVED\", \"DATA\": \"%s\" }",inRemovedPath.c_str()));
}
void WSPPServer::sendPathAddedToClients(const std::string & inAddedPath)	{
	_sendStringToClients(FmtString("{ \"COMMAND\": \"PATH_ADDED\", \"DATA\": \"%s\" }",inAddedPath.c_str()));
}
void WSPPServer::sendJSONStringToClients(const std::string & inJSONString)	{
	_sendStringToClients(inJSONString);
}
/*
void WSPPServer::sendDataToClients(const void * bufferToSend, const int & sizeOfBuffer)	{
	//cout << __PRETTY_FUNCTION__ << endl;
	if (server == nullptr)
		return;
	
	//	get a local copy of my connected clients, run through it, sending the buffer to each of them in turn
	std::vector<connection_hdl>		connsToSendTo(server_conns.begin(), server_conns.end());
	for (const auto & connToSendTo : connsToSendTo)	{
		lib::error_code			ec;
		//server->send(connToSendTo, inStrToSend, frame::opcode::text, ec);
		server->send(connToSendTo, bufferToSend, sizeOfBuffer, websocketpp::frame::opcode::binary, ec);
	}
}
*/
void WSPPServer::sendOSCPacketToListeners(const void * oscPacketToSend, const int & oscPacketSize, const char * listenPath)	{
	if (oscPacketToSend==nullptr || oscPacketSize<=0 || listenPath==nullptr)
		return;
	lock_guard<mutex>		lock(connsLock);
	std::string		tmpListenPath(listenPath);
	const auto		tmpIter = servers_by_listenAddr.find(tmpListenPath);
	//	if none of my clients are listening to this path, bail
	if (tmpIter == servers_by_listenAddr.end())
		return;
	//	get a local copy of the connections that are associated with this OSC path
	vector<connection_hdl>			connsToSendTo = tmpIter->second;
	//	run through the connections
	for (const auto & tmpConn : connsToSendTo)	{
		lib::error_code			ec;
		//	send the passed data to each connection
		server->send(tmpConn, oscPacketToSend, oscPacketSize, websocketpp::frame::opcode::binary, ec);
	}
}


