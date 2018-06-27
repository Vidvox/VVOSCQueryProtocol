#include "WSPPClient.hpp"
#include <websocketpp/close.hpp>

#include "rapidjson/document.h"


WSPPClient::WSPPClient()	{
	//cout << __PRETTY_FUNCTION__ << endl;
	//thread = nullptr;
	client = lib::make_shared<client_t>();
	lib::error_code			ec;
	client->init_asio(ec);
	//client->start_perpetual();	//	can mark this at any time from any thread, so perhaps best to flag it later...
	client->clear_access_channels(log::alevel::all);
	client->set_access_channels(log::alevel::none);
	
	client->set_socket_init_handler([](connection_hdl handler, asio::ip::tcp::socket& s)	{
		asio::ip::tcp::no_delay			option(true);
		//s.set_option(option);
	});
	//	either open or fail will be called for every connection- close will be called for every connection that was opened
	client->set_open_handler([&](connection_hdl hdl)	{
		connected = true;
	});
	
	//	set up null callbacks here
	set_websocket_callback(nullptr);
	set_close_callback(nullptr);
}
WSPPClient::~WSPPClient()	{
	if (isConnected())	{
		disconnect();
	}
	if (isRunning())	{
		stop();
	}
	//client->stop_perpetual();
	client = nullptr;
}


void WSPPClient::set_websocket_callback(WSCallback inCallback)	{
	wsCallback = inCallback;
	
	_performWSCallbackSetup();
}
void WSPPClient::set_osc_callback(OSCCallback inCallback)	{
	oscCallback = inCallback;
	
	_performWSCallbackSetup();
}
void WSPPClient::_performWSCallbackSetup()	{
	if (client != nullptr)	{
		client->set_http_handler([&](connection_hdl hdl)	{
			//cout << __PRETTY_FUNCTION__ << endl;
			//cout << "\t\tmsg is " << msg->get_payload() << endl;
		});
		
		
		client->set_message_handler([&](connection_hdl hdl, client_t::message_ptr msg)	{
			//cout << __PRETTY_FUNCTION__ << endl;
			//cout << "\t\tmsg is " << msg->get_payload() << endl;
		
			WSPPQueryReply			tmpReply;
			
			switch (msg->get_opcode())	{
			case frame::opcode::text:
				{
					rapidjson::Document			tmpJSON;
					tmpJSON.Parse(msg->get_payload().c_str());
					if (tmpJSON.IsObject())	{
						//	if the JSON object meets the COMMAND/DATA pattern
						if (tmpJSON.HasMember("COMMAND") && tmpJSON.HasMember("DATA") && tmpJSON["COMMAND"].IsString())	{
							const char		*tmpCmd = tmpJSON["COMMAND"].GetString();
							if (!strcmp(tmpCmd, "PATH_CHANGED") && tmpJSON["DATA"].IsString())	{
								if (changeCallback != nullptr)
									changeCallback(std::string(tmpJSON["DATA"].GetString()));
							}
							else if (!strcmp(tmpCmd, "PATH_RENAMED") && tmpJSON["DATA"].IsObject())	{
								const auto		&tmpDataObj = tmpJSON["DATA"];
								if (tmpDataObj.HasMember("OLD") && tmpDataObj["OLD"].IsString() && tmpDataObj.HasMember("NEW") && tmpDataObj["NEW"].IsString())	{
									std::string		tmpOldName = tmpDataObj["OLD"].GetString();
									std:;string		tmpNewName = tmpDataObj["NEW"].GetString();
									if (renameCallback != nullptr)
										renameCallback(tmpOldName, tmpNewName);
								}
							}
							else if (!strcmp(tmpCmd, "PATH_REMOVED") && tmpJSON["DATA"].IsString())	{
								if (removeCallback != nullptr)
									removeCallback(std::string(tmpJSON["DATA"].GetString()));
							}
							else if (!strcmp(tmpCmd, "PATH_ADDED") && tmpJSON["DATA"].IsString())	{
								if (addCallback != nullptr)
									addCallback(std::string(tmpJSON["DATA"].GetString()));
							}
							//	else we don't know what kind of COMMAND this is, pass it to the generic websocket callback
							else	{
								wsCallback(msg->get_payload());
							}
						}
					}
					tmpReply = WSPPQueryReply(false);
					
					/*
					tmpReply = (wsCallback == nullptr) ? WSPPQueryReply(false) : wsCallback(msg->get_payload());
					*/
				}
				break;
			case frame::opcode::binary:
				if (oscCallback != nullptr)	{
					const std::string		&tmpString = msg->get_payload();
					oscCallback((void*)tmpString.data(), tmpString.length());
				}
				break;
			default:
				tmpReply = WSPPQueryReply(false);
				break;
			}
			/*
			//	use the provided callback to get a WSPPQueryReply for the message
			const WSPPQueryReply		&tmpReply = (wsCallback==nullptr) ? WSPPQueryReply(false) : wsCallback(msg->get_payload());
			*/
			
			
			//	use the WSPPQueryReply to reply to the message
			lib::error_code			ec;
			client_t::connection_ptr	conn = client->get_con_from_hdl(hdl, ec);
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
void WSPPClient::set_close_callback(CloseCallback inCallback)	{
	closeCallback = inCallback;
	
	client->set_fail_handler([=](connection_hdl hdl)	{
		//cout << __PRETTY_FUNCTION__ << endl;
		lib::error_code			ec;
		std::shared_ptr<void>		actualClientConn = client->get_con_from_hdl(clientConn, ec);
		std::shared_ptr<void>		actualClosedConn = client->get_con_from_hdl(hdl, ec);
		if (actualClientConn == actualClosedConn && actualClientConn != nullptr)	{
			if (closeCallback != nullptr)
				closeCallback();
			connected = false;
			//clientConn = nullptr;
			clientConn = websocketpp::lib::shared_ptr<void>(nullptr);
		}
	});
	client->set_close_handler([=](connection_hdl hdl)	{
		//cout << __PRETTY_FUNCTION__ << endl;
		lib::error_code			ec;
		std::shared_ptr<void>		actualClientConn = client->get_con_from_hdl(clientConn, ec);
		std::shared_ptr<void>		actualClosedConn = client->get_con_from_hdl(hdl, ec);
		if (actualClientConn == actualClosedConn && actualClientConn != nullptr)	{
			if (closeCallback != nullptr)
				closeCallback();
			connected = false;
			//clientConn = nullptr;
			clientConn = websocketpp::lib::shared_ptr<void>(nullptr);
		}
	});
}
void WSPPClient::set_path_changed_callback(SinglePathCallback inCallback)	{
	changeCallback = inCallback;
}
void WSPPClient::set_path_renamed_callback(PathRenamedCallback inCallback)	{
	renameCallback = inCallback;
}
void WSPPClient::set_path_removed_callback(SinglePathCallback inCallback)	{
	removeCallback = inCallback;
}
void WSPPClient::set_path_added_callback(SinglePathCallback inCallback)	{
	addCallback = inCallback;
}


bool WSPPClient::connect(const string & inStringURI)	{
	//cout << __PRETTY_FUNCTION__ << "... " << inStringURI << endl;
	if (!isRunning())	{
		//cout << "\tERR: not running, bailing, " << __PRETTY_FUNCTION__ << endl;
		//return false;
		start();
	}
	if (isConnected())	{
		cout << "\tERR: already connected, bailing, " << __PRETTY_FUNCTION__ << endl;
		return false;
	}
	
	websocketpp::lib::error_code		ec;
	client_t::connection_ptr		conn = client->get_connection(inStringURI, ec);
	if (ec)	{
		cout << "\tERR: connection init error: " << ec.message() << endl;
		return false;
	}
	
	client->connect(conn);
	
	clientConn = conn->get_handle();
	
	//client->start_perpetual();
	
	//client->run();
	
	return true;
}
void WSPPClient::disconnect()	{
	//cout << __PRETTY_FUNCTION__ << endl;
	if (!isRunning())	{
		//cout << "\tERR: not running, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	if (!isConnected())	{
		//cout << "\tERR: not connected, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	
	try	{
		
		//client->pause_reading(clientConn);
		websocketpp::lib::error_code		ec;
		/// Normal closure, meaning that the purpose for which the connection was
		/// established has been fulfilled.
		//static value const normal = 1000;
		//client->close(clientConn, 1000, "told to close", ec);
		//client->close(clientConn, websocketpp::close::status::normal, "", ec);
		client->close(clientConn, websocketpp::close::status::going_away, "", ec);
		if (ec)	{
			cout << "> Error initiating close: " << ec.message() << endl;
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
bool WSPPClient::isConnected()	{
	bool		returnMe = connected;
	return returnMe;
}


void WSPPClient::send(const std::string & inStringToSend)	{
	//cout << __PRETTY_FUNCTION__ << "... " << inStringToSend << endl;
	if (!isRunning())	{
		cout << "\tERR: not running, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	if (!isConnected())	{
		cout << "\tERR: bailing, not connected, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	websocketpp::lib::error_code		ec;
	client->send(clientConn, inStringToSend, websocketpp::frame::opcode::text, ec);
	if (ec)	{
		cout << "\tERR: " << ec.message() << " in " << __PRETTY_FUNCTION__ << endl;
	}
}
void WSPPClient::send(const void * inBuffer, const size_t & inBufferSize)	{
	if (!isRunning())	{
		cout << "\tERR: not running, bailing, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	if (!isConnected())	{
		cout << "\tERR: bailing, not connected, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	if (inBuffer == nullptr)	{
		cout << "\tERR: bailing, no buffer or buffer size is 0, " << __PRETTY_FUNCTION__ << endl;
		return;
	}
	websocketpp::lib::error_code		ec;
	client->send(clientConn, inBuffer, inBufferSize, websocketpp::frame::opcode::binary, ec);
	if (ec)	{
		cout << "\tERR: " << ec.message() << " in " << __PRETTY_FUNCTION__ << endl;
	}
}


void WSPPClient::start()	{
	//cout << __PRETTY_FUNCTION__ << endl;
	if (isRunning())
		return;
	
	client->start_perpetual();
	running = true;
	if (thread == nullptr)
		thread = lib::make_shared<lib::thread>(&client_t::run, &(*client));
	//client->run();
	
	//cout << "\t\t" << __PRETTY_FUNCTION__ << " - FINISHED" << endl;
}
void WSPPClient::stop()	{
	//cout << __PRETTY_FUNCTION__ << endl;
	if (!isRunning())
		return;
	
	disconnect();
	client->stop_perpetual();
	running = false;
	if (thread != nullptr)	{
		thread->join();
		thread = nullptr;
	}
}
bool WSPPClient::isRunning()	{
	bool		returnMe = running;
	return returnMe;
}
