#import <Foundation/Foundation.h>




/**
\file VVOSCQueryConstants.h
*/

/**
\defgroup OSCQUERYCONSTANTS Constants
The OSCQuery specification uses structured JSON objects to communicate data- these constants define the strings which define the structure of these JSON objects.
*/

///@{









/**
\name Minimum required attributes
\brief The OSCQuery spec defines a minimum set of attributes that must be recognized.  Please consult the spec (https://github.com/Vidvox/OSCQueryProposal) for more information about what these attributes mean.
*/
///@{

/// FULL_PATH
extern NSString * kVVOSCQ_ReqAttr_Path;		//	FULL_PATH
/// CONTENTS
extern NSString * kVVOSCQ_ReqAttr_Contents;	//	CONTENTS
/// DESCRIPTION
extern NSString * kVVOSCQ_ReqAttr_Desc;		//	DESCRIPTION
/// TYPE
extern NSString * kVVOSCQ_ReqAttr_Type;		//	TYPE
/// HOST_INFO
extern NSString * kVVOSCQ_ReqAttr_HostInfo;	//	HOST_INFO
/// NAME
extern NSString * kVVOSCQ_ReqAttr_HostInfo_Name;		//	NAME
/// EXTENSIONS
extern NSString * kVVOSCQ_ReqAttr_HostInfo_Exts;		//	EXTENSIONS
/// OSC_IP
extern NSString * kVVOSCQ_ReqAttr_HostInfo_OSCIP;		//	OSC_IP
/// OSC_PORT
extern NSString * kVVOSCQ_ReqAttr_HostInfo_OSCPort;	//	OSC_PORT
/// OSC_TRANSPORT
extern NSString * kVVOSCQ_ReqAttr_HostInfo_OSCTransport;		//	OSC_TRANSPORT
/// WS_IP
extern NSString * kVVOSCQ_ReqAttr_HostInfo_WSIP;	//	WS_IP
/// WS_PORT
extern NSString * kVVOSCQ_ReqAttr_HostInfo_WSPort;	//	WS_PORT

///@}




/**
\name Optional attributes
\brief The OSCQuery spec defines a number of optional attributes used to communicate values that may not be applicable to every node, or supported by every implementation.  These strings are the keys for these optional attributes.  Please consult the spec (https://github.com/Vidvox/OSCQueryProposal) for more information about what these attributes mean.
*/
///@{

/// TAGS
extern NSString * kVVOSCQ_OptAttr_Tags;		//	TAGS
/// EXTENDED_TYPE
extern NSString * kVVOSCQ_OptAttr_Ext_Type;	//	EXTENDED_TYPE
/// ACCESS
extern NSString * kVVOSCQ_OptAttr_Access;		//	ACCESS
/// VALUE
extern NSString * kVVOSCQ_OptAttr_Value;		//	VALUE
/// RANGE
extern NSString * kVVOSCQ_OptAttr_Range;		//	RANGE
/// MIN
extern NSString * kVVOSCQ_OptAttr_Range_Min;	//	MIN
/// MAX
extern NSString * kVVOSCQ_OptAttr_Range_Max;	//	MAX
/// VALS
extern NSString * kVVOSCQ_OptAttr_Range_Vals;	//	VALS
/// CLIPMODE
extern NSString * kVVOSCQ_OptAttr_Clipmode;	//	CLIPMODE
/// UNIT
extern NSString * kVVOSCQ_OptAttr_Unit;		//	UNIT
/// CRITICAL
extern NSString * kVVOSCQ_OptAttr_Critical;	//	CRITICAL
/// OVERLOADS
extern NSString * kVVOSCQ_OptAttr_Overloads;	//	OVERLOADS
/// HTML
extern NSString * kVVOSCQ_OptAttr_HTML;	//	HTML

///@}




/**
\name Possible CLIPMODE attribute values.
\brief The OSCQuery spec defines specific strings as possible values for the CLIPMODE attribute- these strings are those values.
*/
extern NSString * kVVOSCQueryNodeClipModeNone;	//	none
extern NSString * kVVOSCQueryNodeClipModeLow;		//	low
extern NSString * kVVOSCQueryNodeClipModeHigh;	//	high
extern NSString * kVVOSCQueryNodeClipModeBoth;	//	both




/**
\name Possible OSC_TRANSPORT attribute values
\brief The OSCQuery spec defines some strings for declaring whether an OSC server can be reached via UDP or TCP messages- these constants define the possible values that may be stored at the OSC_TRANSPORT key
*/
extern NSString * kVVOSCQueryOSCTransportUDP;		//	UDP
extern NSString * kVVOSCQueryOSCTransportTCP;		//	TCP




/**
\name Optional websocket-related attributes
\brief JSON objects are exchanged over the websocket connection- these JSON objects are expected to have some basic attributes which are defined in the OSCQuery spec: a COMMAND key whose object indicates the action that should be taken, and a DATA key whose object contains further data about the action to be taken.  Please consult the spec (https://github.com/Vidvox/OSCQueryProposal) for more information about what these attributes mean.
*/
///@{

/// COMMAND
extern NSString * kVVOSCQ_WSAttr_Command;	//	COMMAND
/// DATA
extern NSString * kVVOSCQ_WSAttr_Data;		//	DATA

/// LISTEN
extern NSString * kVVOSCQ_WSAttr_Cmd_Listen;	//	LISTEN
/// IGNORE
extern NSString * kVVOSCQ_WSAttr_Cmd_Ignore;	//	IGNORE
/// PATH_CHANGED
extern NSString * kVVOSCQ_WSAttr_Cmd_PathChanged;	//	PATH_CHANGED
/// PATH_RENAMED
extern NSString * kVVOSCQ_WSAttr_Cmd_PathRenamed;	//	PATH_RENAMED
/// PATH_REMOVED
extern NSString * kVVOSCQ_WSAttr_Cmd_PathRemoved;	//	PATH_REMOVED
/// PATH_ADDED
extern NSString * kVVOSCQ_WSAttr_Cmd_PathAdded;	//	PATH_ADDED

///@}











/**
\name Misc
\brief These enums/constants are used internally by this framework, and do not directly correspond to any strings or constants in the OSCQuery specification.
*/
///@{

/**
\name NSNotification names
\brief These are the names of notifications that are posted in response to OSCQuery servers being detected, disappearing offline, etc.
*/
///@{

/// This is the name of the NSNotification that gets posted when a new remote server is created, before the list of remote servers has been updated.  the object posted with the notification is the remote server being created.
extern NSString * kVVOSCQueryRemoteServersNewServerNotification;
/// This is the name of the NSNotification that gets posted when a new remote server is destroyed, before the list of remote servers has been updated.  the object posted with the notification is the remote server being destroyed.
extern NSString * kVVOSCQueryRemoteServersRemovedServerNotification;
/// This is the name of the NSNotification that gets posted after the list of remote servers has been updated
extern NSString * kVVOSCQueryRemoteServersUpdatedNotification;

///@}




/*
\name Access enum
\brief The OSCQuery spec defines an ACCESS attribute that describes whether the value associated with an OSC method on a remote server is readable, writable, etc.  This enum describes the possible values for this attribute.
*/
typedef NS_ENUM(NSInteger, VVOSCQueryNodeAccess)	{
	VVOSCQueryNodeAccess_None = 0,
	VVOSCQueryNodeAccess_Read = 0x01,
	VVOSCQueryNodeAccess_Write = 0x02,
	VVOSCQueryNodeAccess_RW = 0x03
};




/*
\name OSC transport enum
\brief This enum depicts the transport method used by an OSC server, which is described in the spec (in the HOST_INFO param)
*/
typedef NS_ENUM(NSInteger, VVOSCQueryOSCTransportType)	{
	VVOSCQueryOSCTransportType_Unknown = 0,
	VVOSCQueryOSCTransportType_UDP,
	VVOSCQueryOSCTransportType_TCP
};




/*
Most OSC queries are "recursive" in the sense that they're going to return a full tree of OSC nodes, gathered recursively.  Really, the only queries that aren't recursive are queries requesting a single specific attribute.  because of this, we maintain an array of all the optional query attributes that would mean that a query isn't recursive.
*/
#if __has_feature(objc_arc)
extern NSArray<NSString*> * kVVOSCQ_NonRecursiveAttrs;
#else
extern NSArray * kVVOSCQ_NonRecursiveAttrs;
#endif

///@}













///@}




@interface VVOSCQueryConstants : NSObject

@end
