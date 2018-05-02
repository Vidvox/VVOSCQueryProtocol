#import <Foundation/Foundation.h>


/*		this enum describes the access to an OSC node described in the spec			*/
typedef NS_ENUM(NSInteger, VVOSCQueryNodeAccess)	{
	VVOSCQueryNodeAccess_None = 0,
	VVOSCQueryNodeAccess_Read = 0x01,
	VVOSCQueryNodeAccess_Write = 0x02,
	VVOSCQueryNodeAccess_RW = 0x03
};


//		the spec defines a minimum set of attributes that must be supported/returned:
extern NSString * kVVOSCQ_ReqAttr_Path;		//	FULL_PATH
extern NSString * kVVOSCQ_ReqAttr_Contents;	//	CONTENTS
extern NSString * kVVOSCQ_ReqAttr_Desc;		//	DESCRIPTION
extern NSString * kVVOSCQ_ReqAttr_Type;		//	TYPE
extern NSString * kVVOSCQ_ReqAttr_HostInfo;	//	HOST_INFO
extern NSString * kVVOSCQ_ReqAttr_HostInfo_Name;		//	NAME
extern NSString * kVVOSCQ_ReqAttr_HostInfo_Exts;		//	EXTENSIONS
extern NSString * kVVOSCQ_ReqAttr_HostInfo_OSCIP;		//	OSC_IP
extern NSString * kVVOSCQ_ReqAttr_HostInfo_OSCPort;	//	OSC_PORT
extern NSString * kVVOSCQ_ReqAttr_HostInfo_OSCTransport;		//	OSC_TRANSPORT
extern NSString * kVVOSCQ_ReqAttr_HostInfo_WSIP;	//	WS_IP
extern NSString * kVVOSCQ_ReqAttr_HostInfo_WSPort;	//	WS_PORT


/*		the spec defines a number of optional attributes used to communicate values that may not be 
applicable to every node, or supported by every implementation.  these strings are the keys for 
these optional attributes.			*/
extern NSString * kVVOSCQ_OptAttr_Tags;		//	TAGS
extern NSString * kVVOSCQ_OptAttr_Ext_Type;	//	EXTENDED_TYPE
//extern NSString * kVVOSCQ_OptAttr_Type;		//	TYPE
extern NSString * kVVOSCQ_OptAttr_Access;		//	ACCESS
extern NSString * kVVOSCQ_OptAttr_Value;		//	VALUE
extern NSString * kVVOSCQ_OptAttr_Range;		//	RANGE
extern NSString * kVVOSCQ_OptAttr_Range_Min;	//	MIN
extern NSString * kVVOSCQ_OptAttr_Range_Max;	//	MAX
extern NSString * kVVOSCQ_OptAttr_Range_Vals;	//	VALS
extern NSString * kVVOSCQ_OptAttr_Clipmode;	//	CLIPMODE
extern NSString * kVVOSCQ_OptAttr_Unit;		//	UNIT
extern NSString * kVVOSCQ_OptAttr_Critical;	//	CRITICAL
extern NSString * kVVOSCQ_OptAttr_Overloads;	//	OVERLOADS
extern NSString * kVVOSCQ_OptAttr_HTML;	//	HTML

/*		most OSC queries are "recursive" in the sense that they're going to return a full tree of 
OSC nodes, gathered recursively.  really, the only queries that aren't recursive are queries 
requesting a single specific attribute.  because of this, we maintain an array of all the optional 
query attributes that would mean that a query isn't recursive.			*/
#if __has_feature(objc_arc)
extern NSArray<NSString*> * kVVOSCQ_NonRecursiveAttrs;
#else
extern NSArray * kVVOSCQ_NonRecursiveAttrs;
#endif

//	the spec defines specific strings as possible values for the CLIPMODE attribute- these strings are those values
extern NSString * kVVOSCQueryNodeClipModeNone;	//	none
extern NSString * kVVOSCQueryNodeClipModeLow;		//	low
extern NSString * kVVOSCQueryNodeClipModeHigh;	//	high
extern NSString * kVVOSCQueryNodeClipModeBoth;	//	both

//	the spec defines some strings for declaring whether an OSC server can be reached via UDP or TCP messages- these constants define the possible values that may be stored at the OSC_TRANSPORT key
extern NSString * kVVOSCQueryOSCTransportUDP;		//	UDP
extern NSString * kVVOSCQueryOSCTransportTCP;		//	TCP



/*	JSON objects are exchanged over the websocket connection- these JSON objects are expected to 
have some basic attributes, a COMMAND key whose object indicates the action that should be taken, 
and a DATA key whose object contains further data about the action to be taken.			*/
extern NSString * kVVOSCQ_WSAttr_Command;	//	COMMAND
extern NSString * kVVOSCQ_WSAttr_Data;		//	DATA

extern NSString * kVVOSCQ_WSAttr_Cmd_Listen;	//	LISTEN
extern NSString * kVVOSCQ_WSAttr_Cmd_Ignore;	//	IGNORE
extern NSString * kVVOSCQ_WSAttr_Cmd_PathChanged;	//	PATH_CHANGED
extern NSString * kVVOSCQ_WSAttr_Cmd_PathRenamed;	//	PATH_RENAMED
extern NSString * kVVOSCQ_WSAttr_Cmd_PathRemoved;	//	PATH_REMOVED
extern NSString * kVVOSCQ_WSAttr_Cmd_PathAdded;	//	PATH_ADDED




/*		this is the name of the NSNotification that gets posted when a new remote server is 
created, before the list of remote servers has been updated.  the object posted with the 
notification is the remote server being created.		*/
extern NSString * kVVOSCQueryRemoteServersNewServerNotification;
/*		this is the name of the NSNotification that gets posted when a new remote server is 
destroyed, before the list of remote servers has been updated.  the object posted with the 
notification is the remote server being destroyed.		*/
extern NSString * kVVOSCQueryRemoteServersRemovedServerNotification;
/*	this is the name of the NSNotification that gets posted after the list of remote servers has been updated			*/
extern NSString * kVVOSCQueryRemoteServersUpdatedNotification;




//	this enum depicts the transport method used by an OSC server, which is described in the spec (in the HOST_INFO param)
typedef NS_ENUM(NSInteger, VVOSCQueryOSCTransportType)	{
	VVOSCQueryOSCTransportType_Unknown = 0,
	VVOSCQueryOSCTransportType_UDP,
	VVOSCQueryOSCTransportType_TCP
};




@interface VVOSCQueryConstants : NSObject

@end
