//
//  NSObject+CWProxy.m
//  CWFoundation
//  Created by Fredrik Olsson 
//
//  Copyright (c) 2011, Jayway AB All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Jayway AB nor the names of its contributors may 
//       be used to endorse or promote products derived from this software 
//       without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL JAYWAY AB BE LIABLE FOR ANY DIRECT, INDIRECT, 
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "NSObject+CWProxy.h"

#import "NSOperationQueue+CWDefaultQueue.h"

typedef enum {
	CWProxyTargetBackgound,
	CWProxyTargetThread,
	CWProxyTargetQueue,
} CWProxyTarget;

@interface CWProxy : NSObject {
@private
    id _object;
    CWProxyTarget _proxyTarget;
    NSThread* _thread;
    NSOperationQueue* _queue;
    BOOL _wait;
    NSTimeInterval _delay;
}

+(id)proxyForObject:(id)object;
+(id)proxyForObject:(id)object onThread:(NSThread*)thread;
+(id)proxyForObject:(id)object onQueue:(NSOperationQueue*)queue;

@end



@implementation NSObject (CWProxy)

-(id)mainProxy;
{
    return [self proxyForThread:[NSThread mainThread]];
}

-(id)backgroundProxy;
{
    return [CWProxy proxyForObject:self];
}

-(id)proxyForThread:(NSThread*)thread;
{
    if (thread == [NSThread currentThread]) {
        return self;
    } else {
        return [CWProxy proxyForObject:self onThread:thread];
    }
}

-(id)queueProxy;
{
    return [self proxyForQueue:[NSOperationQueue defaultQueue]];
}

-(id)proxyForQueue:(NSOperationQueue*)queue;
{
    return [CWProxy proxyForObject:self onQueue:queue];
}

-(id)waitUntilDone;
{
    return self;
}

-(id)afterDelay:(NSTimeInterval)delay;
{
	CWProxy* proxy = [CWProxy proxyForObject:self onThread:[NSThread currentThread]];
    return [proxy afterDelay:delay];
}

@end


@implementation CWProxy

+(id)proxyForObject:(id)object;
{
    CWProxy* proxy = [[[self alloc] init] autorelease];
    proxy->_object = [object retain];
    proxy->_proxyTarget = CWProxyTargetBackgound;
    return proxy;
}

+(id)proxyForObject:(id)object onThread:(NSThread*)thread;
{
    CWProxy* proxy = [[[self alloc] init] autorelease];
    proxy->_object = [object retain];
    proxy->_proxyTarget = CWProxyTargetThread;
    proxy->_thread = [thread retain];
    return proxy;
}

+(id)proxyForObject:(id)object onQueue:(NSOperationQueue*)queue;
{
    CWProxy* proxy = [[[self alloc] init] autorelease];
    proxy->_object = [object retain];
    proxy->_proxyTarget = CWProxyTargetQueue;
    proxy->_queue = [queue retain];
    return proxy;
}

-(void)dealloc;
{
    [_object release];
    [_thread release];
    [_queue release];
    [super dealloc];
}

-(BOOL)respondsToSelector:(SEL)aSelector;
{
    return [super respondsToSelector:aSelector] || [_object respondsToSelector:aSelector];
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector;
{
	if ([_object respondsToSelector:aSelector]) {
	    return [_object methodSignatureForSelector:aSelector];
    } else {
    	return [super methodSignatureForSelector:aSelector];
    }
}

-(void)forwardInvocation:(NSInvocation *)invocation;
{
    if (_delay > 0) {
    	[self performSelector:_cmd 
                   withObject:invocation 
                   afterDelay:_delay];
        _delay = 0;
        return;
    }
	switch (_proxyTarget) {
        case CWProxyTargetBackgound:
            [self performSelectorInBackground:@selector(wrapInvocation:) 
                                   withObject:invocation];
            break;
        case CWProxyTargetThread:
            [self performSelector:@selector(wrapInvocation:) 
                         onThread:_thread 
                       withObject:invocation
                    waitUntilDone:_wait];
            break;
        case CWProxyTargetQueue: {
			NSInvocationOperation* operation = [self performSelector:@selector(wrapInvocation:)
                                                             onQueue:_queue 
                                                          withObject:invocation];
            if (_wait) {
            	[operation waitUntilFinished];
            }
            break;
        }
    }
}

-(void)wrapInvocation:(NSInvocation*)invocation;
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [invocation invokeWithTarget:_object];
    [pool release];
}

-(id)waitUntilDone;
{
    _wait = YES;
    return self;
}

-(id)afterDelay:(NSTimeInterval)delay;
{
    _delay = delay;
    return self;
}

@end


