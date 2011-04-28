//
//  CWNetworkMonitor.h
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
//     * Neither the name of the Jayway nor the names of its contributors may 
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

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>


/*!
 * @abstract Sent when network status is first known and on any subsequent changes.
 * @discussion The object for this notification is the originating CWNetworkMonitor instance.
 */
extern NSString* const CWNetWorkStatusDidChangeNotification;


typedef enum {
	CWNetworkStatusUnknown = -1,
    CWNetworkStatusNotAvailable = 0,
    CWNetworkStatusAvailableViaWWAN = 1,
    CWNetworkStatusAvailableViaWiFi = 2
} CWNetworkStatus;


/*!
 * @abstract Utility class for monitoring the availability of the network.
 */
@interface CWNetworkMonitor : NSObject {
@private
	NSString* _hostName;
	SCNetworkReachabilityRef _reachabilityRef;
    CWNetworkStatus _lastKnownStatus;
    BOOL _isMonitoring;
    BOOL _isLocalWiFi;
}

/*!
 * @abstract get the receivers monitored host name.
 * @discussion Yield an IP address if not monitoring a specific host by name.
 */
@property(nonatomic, readonly, copy) NSString* hostName;

/*!
 * @abstract Get the default CWNetworkMonitor instance.
 * @discussion Lazily create a monitor for internet connection if not yet set.
 */
+(CWNetworkMonitor*)defaultMonitor;

/*!
 * @abstract Set or replace the default CWNetWorkMonitor instance.
 */
+(void)setDefaultMonitor:(CWNetworkMonitor*)monitor;

/*!
 * @abstract Get a new monitor for internet connection.
 * @discussion Use for general internet connectivity test.
 */
+(CWNetworkMonitor*)monitorForInternetConnection;

/*!
 * @abstract Get a new monitor for local WiFi connection.
 */
+(CWNetworkMonitor*)monitorForLocalWiFi;

/*!
 * @abstract Get a new monitor for specific host by name.
 * @dicsussion For example @"service.jayway.com" or "google.com".
 */
+(CWNetworkMonitor*)monitorWithHostName:(NSString*)hostName;

/*!
 * @abstract Get a new monitor for specific host by address.
 */
+(CWNetworkMonitor*)monitorWithAddress:(const struct sockaddr_in*)hostAddress;

/*!
 * @abstract Get the current network status.
 * @discussion Non blocking. Will always yield CWNetworkStatusUnknown if the 
 *             receiver is not currently monitoring.
 */
-(CWNetworkStatus)networkStatus;

/*!
 * @abstract Query if any kind of network is available.
 * @discussion Non blocking. Will always yield NO if the receiver is not
 *             currently monitoring.
 */
-(BOOL)isAvailable;

/*!
 * @abstract Query if the receiver is currently monitoring.
 */
-(BOOL)isMonitoringNetworkStatus;

/*!
 * @abstract Start monitoring network status using the receiver.
 * @discussion The receiver will post a CWNetWorkStatusDidChangeNotification
 *             notification at the earliest possible moment wit the current status,
 *             and will them continue to post this notification for any changes to
 *             the network status.
 */
-(BOOL)startMonitoringNetworkStatus;

/*!
 * @abstract Stop monitoring network status using the receiver.
 */
-(void)stopMonitoringNetworkStatus;

@end
