#ifndef WSPPQueryReply_h
#define WSPPQueryReply_h

/*		this WSPPQueryReply class exists to provide a simple wrapper for passing reply data between handlers.  the nature of the init methods means that an instance of WSPPQueryReply will either be a string, or an error code, or a flag indicating that no reply should be performed.		*/

class WSPPQueryReply	{
private:
	std::string		replyString{""};
	int				replyCode{-1};
	bool			performReply{false};
public:
	WSPPQueryReply() {}
	WSPPQueryReply(const std::string & rs) : replyString(rs), replyCode(-1), performReply(true) {}
	WSPPQueryReply(const int & rc) : replyString(""), replyCode(rc), performReply(true) {}
	WSPPQueryReply(const bool & pr, const std::string & rs="") : replyString(rs), replyCode(-1), performReply(pr) {}
	~WSPPQueryReply() {}
	
	const std::string & getReplyString() const	{	return replyString;	}
	const int & getReplyCode() const	{	return replyCode;	}
	const bool & getPerformReply() const	{	return performReply;	}
};




#endif /* WSPPQueryReply_h */
