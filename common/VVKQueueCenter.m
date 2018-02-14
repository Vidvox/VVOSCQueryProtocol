#import "VVKQueueCenter.h"




id			_mainVVKQueueCenter = nil;




@interface VVKQueueCenter ()
- (void) updateEntries;
- (BOOL) startConnectionForPathIfNeeded:(NSString *)p fileDescriptor:(int)fd;
- (void) closeConnectionForPathIfNeeded:(NSString *)p fileDescriptor:(int)fd;
@end




@implementation VVKQueueCenter


+ (void) initialize	{
	_mainVVKQueueCenter = [[VVKQueueCenter alloc] init];
}
+ (id) mainCenter	{
	return _mainVVKQueueCenter;
}
+ (void) addObserver:(id)o forPath:(NSString *)p	{
	[_mainVVKQueueCenter addObserver:o forPath:p];
}
+ (void) removeObserver:(id)o	{
	[_mainVVKQueueCenter removeObserver:o];
}
+ (void) removeObserver:(id)o forPath:(NSString *)p	{
	[_mainVVKQueueCenter removeObserver:o forPath:p];
}
- (id) init	{
	self = [super init];
	if (self != nil)	{
		kqueueFD = -1;
		
		pthread_mutexattr_t		attr;
		pthread_mutexattr_init(&attr);
		pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&entryLock, &attr);
		pthread_mutexattr_destroy(&attr);
		
		entries = [[NSMutableArray alloc] init];
		entryChanges = [[NSMutableArray alloc] init];
		threadHaltFlag = NO;
		currentlyProcessing = NO;
		
		kqueueFD = kqueue();
		if (kqueueFD == -1)	{
			NSLog(@"\t\terr: couldn't create kqueueFD: %d",kqueueFD);
			self = nil;
			return self;
		}
		
		[NSThread detachNewThreadSelector:@selector(threadLaunch:) toTarget:self withObject:nil];
	}
	return self;
}
- (void) dealloc	{
	threadHaltFlag = YES;
	while (currentlyProcessing)
		pthread_yield_np();
	if (kqueueFD != -1)
		close(kqueueFD);
	pthread_mutex_destroy(&entryLock);
	entries = nil; 
	entryChanges = nil;
}


- (void) threadLaunch:(id)sender	{
	int						fileDescriptor = kqueueFD;
	
	currentlyProcessing = YES;
	while (!threadHaltFlag)	{
		@autoreleasepool	{
			int						n;
			struct kevent			event;
			struct timespec			timeout = {1,0};
			
			[self updateEntries];
			
			n = kevent(kqueueFD, NULL, 0, &event, 1, &timeout);
			
			if ([entryChanges count]>0)
				[self updateEntries];
			
			if (n > 0)	{
				//NSLog(@"\t\tfound event");
				if (event.filter == EVFILT_VNODE)	{
					if (event.fflags)	{
						NSString		*path = (__bridge NSString *)event.udata;
						//	find all the entries matching the path
						NSMutableArray	*entriesToPing = nil;
						pthread_mutex_lock(&entryLock);
						for (VVKQueueEntry *entry in entries)	{
							NSString		*entryPath = [entry path];
							if (entryPath!=nil && [entryPath isEqualToString:path])	{
								if (entriesToPing == nil)
									entriesToPing = [[NSMutableArray alloc] init];
								[entriesToPing addObject:entry];
							}
						}
						pthread_mutex_unlock(&entryLock);
						//	if there are entries to ping- do so now!
						for (VVKQueueEntry *entry in entriesToPing)	{
							dispatch_async(dispatch_get_main_queue(), ^{
								[[entry delegate] file:path changed:event.fflags];
							});
						}
					}
				}
			}
			
			//	purge an entries with nil delegates (which will happen if the delegate was freed but not remvoed as an observer)
			NSMutableIndexSet	*indexesToDelete = nil;
			pthread_mutex_lock(&entryLock);
			NSInteger			tmpIndex = 0;
			for (VVKQueueEntry *entry in entries)	{
				if ([entry delegate]==nil)	{
					if (indexesToDelete == nil)
						indexesToDelete = [[NSMutableIndexSet alloc] init];
					[indexesToDelete addIndex:tmpIndex];
				}
				++tmpIndex;
			}
			if (indexesToDelete != nil)
				[entries removeObjectsAtIndexes:indexesToDelete];
			pthread_mutex_unlock(&entryLock);
		}
	}
	
	close(fileDescriptor);
	currentlyProcessing = NO;
	
}


- (void) addObserver:(id)o forPath:(NSString *)p	{
	NSLog(@"%s ... %@, %@",__func__,o,p);
	//	make an entry
	VVKQueueEntry		*newEntry = [VVKQueueEntry createWithDelegate:o path:p];
	if (newEntry == nil)
		return;
	//	we want this entry to be an "add"
	[newEntry setAddFlag:YES];
	//	add it to the array of changes
	pthread_mutex_lock(&entryLock);
	[entryChanges addObject:newEntry];
	pthread_mutex_unlock(&entryLock);
}
- (void) removeObserver:(id)o	{
	//	make an entry
	VVKQueueEntry		*newEntry = [VVKQueueEntry createWithDelegate:o path:nil];
	if (newEntry == nil)
		return;
	//	we want this entry to be an "remove"
	[newEntry setAddFlag:NO];
	//	add it to the array of changes
	pthread_mutex_lock(&entryLock);
	[entryChanges addObject:newEntry];
	pthread_mutex_unlock(&entryLock);
}
- (void) removeObserver:(id)o forPath:(NSString *)p	{
	NSLog(@"%s ... %@, %@",__func__,o,p);
	//	make an entry
	VVKQueueEntry		*newEntry = [VVKQueueEntry createWithDelegate:o path:p];
	if (newEntry == nil)
		return;
	//	we want this entry to be an "remove"
	[newEntry setAddFlag:NO];
	//	add it to the array of changes
	pthread_mutex_lock(&entryLock);
	[entryChanges addObject:newEntry];
	pthread_mutex_unlock(&entryLock);
}


- (void) updateEntries	{
	//	copy the contents of 'entryChanges', then clear it out
	pthread_mutex_lock(&entryLock);
	NSMutableArray		*tmpChanges = [entryChanges copy];
	[entryChanges removeAllObjects];
	pthread_mutex_unlock(&entryLock);
	
	//	run through the copied entries, applying their changes
	for (VVKQueueEntry *tmpEntry in tmpChanges)	{
		NSString	*tmpPath = [tmpEntry path];
		id			tmpDelegate = [tmpEntry delegate];
		//	if we're supposed to be adding this entry...
		if ([tmpEntry addFlag])	{
			//	calculate and set the entry's file descriptor...
			int			fileDescriptor = open([tmpPath fileSystemRepresentation], O_EVTONLY, 0);
			if (fileDescriptor < 0)	{
				NSLog(@"error: entries count %ld on failure to opening rep. for path to watch, %s : %@",[entries count],__func__,tmpPath);
				continue;
			}
			[tmpEntry setFD:[NSNumber numberWithInteger:fileDescriptor]];
			
			//	start the connection
			[self startConnectionForPathIfNeeded:tmpPath fileDescriptor:fileDescriptor];
			
			//	add the entry to the array of entries AFTER STARTING THE CONNECTION (order is important)
			pthread_mutex_lock(&entryLock);
			[entries addObject:tmpEntry];
			pthread_mutex_unlock(&entryLock);
		}
		else	{
			//	remove the entry (or entries!) from the array of entries BEFORE CLOSING THE CONNECTION (order is important)
			
			NSMutableIndexSet		*indexesToRemove = nil;
			NSArray					*entriesToRemove = nil;
			NSInteger				tmpIndex = 0;
			pthread_mutex_lock(&entryLock);
			//	if there's no "path", then we want to remove all existing entries that match the tmp entry's delegate
			if (tmpPath == nil)	{
				for (VVKQueueEntry *existingEntry in entries)	{
					if ([existingEntry delegate] == tmpDelegate)	{
						if (indexesToRemove == nil)
							indexesToRemove = [[NSMutableIndexSet alloc] init];
						[indexesToRemove addIndex:tmpIndex];
					}
					++tmpIndex;
				}
			}
			//	else there's a "path"- we want to remove only the entries that are an exact match to the tmp entry's delegate/path
			else	{
				for (VVKQueueEntry *existingEntry in entries)	{
					id<VVKQueueCenterDelegate>	existingDelegate = [existingEntry delegate];
					NSString		*existingPath = [existingEntry path];
					if (existingDelegate==tmpDelegate && existingPath!=nil && [existingPath isEqualToString:tmpPath])	{
						if (indexesToRemove == nil)
							indexesToRemove = [[NSMutableIndexSet alloc] init];
						[indexesToRemove addIndex:tmpIndex];
					}
					++tmpIndex;
				}
			}
			//	copy the entries we're about to remove (we want their FDs), then remove them from the array of entries
			if (indexesToRemove != nil)	{
				entriesToRemove = [entries objectsAtIndexes:indexesToRemove];
				[entries removeObjectsAtIndexes:indexesToRemove];
			}
			pthread_mutex_unlock(&entryLock);
			
			//	run through the array of entries we just removed from the array, closing the connection for each
			for (VVKQueueEntry *entryToRemove in entriesToRemove)	{
				//	close the connection AFTER REMOVING THE ENTRIES FROM THE ARRAY (order is important)
				[self closeConnectionForPathIfNeeded:[entryToRemove path] fileDescriptor:[[entryToRemove fd] intValue]];
			}
		}
	}
}
- (BOOL) startConnectionForPathIfNeeded:(NSString *)p fileDescriptor:(int)fd	{
	//NSLog(@"%s",__func__);
	if (p == nil)
		return NO;
		
	BOOL	needsStart = YES;
	//	Go through the paths array
	//	If a match is found, BAIL
	pthread_mutex_lock(&entryLock);
	for (VVKQueueEntry *entry in entries)	{
		NSString		*entryPath = [entry path];
		if (entryPath!=nil && [entryPath isEqualToString:p])	{
			needsStart = NO;
			break;
		}
	}
	pthread_mutex_unlock(&entryLock);
	
	if (needsStart)	{
		//NSLog(@"\t\t %@ with fd %ld", p, fd);
		struct kevent		event;
		struct timespec		tmpTime = {0,0};
		EV_SET(&event,
			fd,
			EVFILT_VNODE,
			EV_ADD | EV_ENABLE | EV_CLEAR,
			NOTE_RENAME | NOTE_WRITE | NOTE_DELETE | NOTE_ATTRIB,
			0,
			(__bridge void*)[p copy]);
			
		kevent(kqueueFD, &event, 1, NULL, 0, &tmpTime);
	}
	
	return needsStart;
}
- (void) closeConnectionForPathIfNeeded:(NSString *)p fileDescriptor:(int)fd	{
	//NSLog(@"%s",__func__);
	if (p == nil)
		return;
		
	BOOL	needsClose = YES;
	//	Go through the paths array
	//	If a match is found, BAIL
	pthread_mutex_lock(&entryLock);
	for (VVKQueueEntry *entry in entries)	{
		NSString		*entryPath = [entry path];
		if (entryPath!=nil && [entryPath isEqualToString:p])	{
			needsClose = NO;
			break;
		}
	}
	pthread_mutex_unlock(&entryLock);
	
	if (needsClose)	{
		//NSLog(@"\t\tclosing %@ with fd %ld", p, fd);
		close(fd);
	}
}


@end



#pragma mark -
#pragma mark -



@implementation VVKQueueEntry


+ (id) createWithDelegate:(id<VVKQueueCenterDelegate>)d path:(NSString *)p	{
	return [[VVKQueueEntry alloc] initWithDelegate:d path:p];
}
- (id) initWithDelegate:(id<VVKQueueCenterDelegate>)d path:(NSString *)p	{
	self = [super init];
	if (self != nil)	{
		path = nil;
		fd = nil;
		delegate = nil;
		[self setDelegate:d];
		[self setPath:p];
	}
	return self;
}
- (void) dealloc	{
	[self setPath:nil];
	[self setFD:nil];
	[self setDelegate:nil];
}
@synthesize path;
@synthesize fd;
@synthesize delegate;
@synthesize addFlag;


@end
