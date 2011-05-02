//
//  NSObjectAssociatedObjectsTest.m
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

#import "NSObjectAssociatedObjectsTest.h"
#import "NSObject+CWAssociatedObject.h"

@implementation NSObjectAssociatedObjectsTest

static char* const key = "key";  

-(void)setUp;
{
	object = [[NSMutableArray alloc] init];
    associatedObject = [[NSMutableDictionary alloc] init];
    STAssertEquals([object retainCount], 1u, @"Object retain count should be 1");
    STAssertEquals([associatedObject retainCount], 1u, @"Associated object retain count should be 1");
}

-(void)tearDown;
{
    STAssertNoThrow([object release], @"Object can be release");
    STAssertNoThrow([associatedObject release], @"Associated object can be release");
    object = nil;
    associatedObject = nil;
}

-(void)testAssociatedObjectsAssignPolicy;
{
    [object setAssociatedObject:associatedObject
                   forStaticKey:key
          withAssociationPolicy:OBJC_ASSOCIATION_ASSIGN];
    STAssertEquals([object retainCount], 1u, @"Object retain count should be 1");
    STAssertEquals([associatedObject retainCount], 1u, @"Associated object retain count should be 1");
    id fetchedObject = [object associatedObjectForStaticKey:key];
	STAssertTrue(associatedObject == fetchedObject, @"Fetched associated object is pointer identity.");
}

-(void)testAssociatedObjectsCopyPolicy;
{
    [object setAssociatedObject:associatedObject
                   forStaticKey:key
          withAssociationPolicy:OBJC_ASSOCIATION_COPY_NONATOMIC];
    STAssertEquals([object retainCount], 1u, @"Object retain count should be 1");
    STAssertEquals([associatedObject retainCount], 1u, @"Associated object retain count should be 1");
    id fetchedObject = [object associatedObjectForStaticKey:key];
	STAssertTrue(associatedObject != fetchedObject, @"Fetched associated object is not pointer identity.");
}

-(void)testAssociatedObjectsRetainPolicy;
{
    [object setAssociatedObject:associatedObject
                   forStaticKey:key
          withAssociationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
    STAssertEquals([object retainCount], 1u, @"Object retain count should be 1");
    STAssertEquals([associatedObject retainCount], 2u, @"Associated object retain count should be 2");
    id fetchedObject = [object associatedObjectForStaticKey:key];
	STAssertTrue(associatedObject == fetchedObject, @"Fetched associated object is pointer identity.");
}

@end
