#include "VVOSCQueryStringUtilities.hpp"

std::string FmtString(const char * fmt, ...)	{
	va_list			args;
	va_start(args, fmt);
	int				tmpLen = vsnprintf(nullptr, 0, fmt, args) + 1;
	va_end(args);
	
	if (tmpLen < 1)
		return std::string("");
	
	va_start(args, fmt);
	char			buf[tmpLen];
	memset(buf, 0, tmpLen);
	vsnprintf(buf, tmpLen, fmt, args);
	va_end(args);
	
	return std::string(buf);
}
