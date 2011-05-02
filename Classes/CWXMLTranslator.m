//
//  CWXMLTranslator.m
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

#import "CWXMLTranslator.h"
#import "CWLog.h"
#import "NSInvocation+CWVariableArguments.h"
#import "CWXMLTranslation.h"

@interface CWXMLTranslatorState : NSObject
{
@public
	NSDictionary* translationPlist;
    id currentObject;
    NSString* elementName;
    NSDictionary* attributes;
    int nestingCount;
}

-(id)initWithObject:(id)object;

@end

@implementation CWXMLTranslatorState

-(id)initWithObject:(id)object;
{
    self = [super init];
    if (self) {
        elementName = @"";
		currentObject = [object retain];
    }
    return self;
}

-(void)dealloc;
{
    [elementName release], elementName = nil;
    [attributes release], attributes = nil;
	[currentObject release];
    [super dealloc];
}

@end

static NSDateFormatter* _defaultDateFormatter = nil;


@implementation CWXMLTranslator

#pragma mark --- Properties

@synthesize delegate = _delegate;

-(void)setDelegate:(id<CWXMLTranslatorDelegate>)delegate;
{
	if (_delegate != delegate) {
    	_delegate = delegate;
    	_delegateFlags.objectInstanceOfClass = [delegate respondsToSelector:@selector(xmlTranslator:objectInstanceOfClass:fromXMLname:xmlAttributes:toKey:shouldSkip:)];
    	_delegateFlags.didTranslateObject = [delegate respondsToSelector:@selector(xmlTranslator:didTranslateObject:fromXMLName:toKey:ontoObject:)];
    	_delegateFlags.primitiveObjectInstanceOfClass = [delegate respondsToSelector:@selector(xmlTranslator:primitiveObjectInstanceOfClass:withString:fromXMLname:xmlAttributes:toKey:shouldSkip:)];
    }
}

+ (NSDateFormatter*) defaultDateFormatter;
{
	if (_defaultDateFormatter == nil) {
		_defaultDateFormatter = [[NSDateFormatter alloc] init];
        [_defaultDateFormatter setLenient:YES];
	}
	return _defaultDateFormatter;
}

+ (void) setDefaultDateFormatter:(NSDateFormatter *)formatter;
{
	if (formatter != _defaultDateFormatter) {
		[_defaultDateFormatter release];
		_defaultDateFormatter = [formatter retain];
	}
}


#pragma mark --- Convinience methods

+(NSArray*)translateContentsOfData:(NSData*)data withTranslationNamed:(NSString*)translationName delegate:(id<CWXMLTranslatorDelegate>)delegate error:(NSError**)error;
{
    id translation = [CWXMLTranslation translationNamed:translationName];
    if (translation) {
        CWXMLTranslator* translator = [[[self alloc] initWithTranslation:translation
                                                                delegate:delegate] autorelease];
        return [translator translateContentsOfData:data error:error];
    }
    return nil; 
}

+(NSArray*)translateContentsOfURL:(NSURL*)url withTranslationNamed:(NSString*)translationName delegate:(id<CWXMLTranslatorDelegate>)delegate error:(NSError**)error;
{
    id translation = [CWXMLTranslation translationNamed:translationName];
    if (translation) {
        CWXMLTranslator* translator = [[[self alloc] initWithTranslation:translation
                                                                delegate:delegate] autorelease];
        return [translator translateContentsOfURL:url error:error];
    }
    return nil; 
}

#pragma mark --- Instance life cycle

-(id)initWithTranslation:(id)translation delegate:(id<CWXMLTranslatorDelegate>)delegate;
{
	self = [self init];
    if (self) {
        translationPlist = [translation copy];
        self.delegate = delegate; 
    }
    return self;
}

-(void)dealloc;
{
	[translationPlist release];
	[stateStack release];
    [currentText release];
    [super dealloc];
}


#pragma mark --- Public API

-(NSArray*)translateWithXMLParser:(NSXMLParser*)parser error:(NSError**)error;
{
    BOOL result = NO;
    didAbort = NO;
    xmlParser = [parser retain];
    rootObjects = [NSMutableArray array];
    [xmlParser setDelegate:(id)self];
    CWXMLTranslatorState* state = [[CWXMLTranslatorState alloc] init];
    state->translationPlist = translationPlist;
    stateStack = [[NSMutableArray alloc] initWithObjects:state, nil];
    [state release];
    result = [xmlParser parse];
    if (!result) {
        if (didAbort) {
            result = YES;
        } else if (error) {
            *error = [xmlParser parserError];          
        }
    }
    [stateStack release];
    stateStack = nil;
    [xmlParser release];
    xmlParser = nil;
    if (result == NO) {
        CWLogError(@"Unparsable data in %@", parser);
        rootObjects = nil;
    }
	return [[rootObjects copy] autorelease];
}

-(NSArray*)translateContentsOfData:(NSData*)data error:(NSError**)error;
{
    NSXMLParser* parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
    if (parser) {
    	return [self translateWithXMLParser:parser
                                      error:error];
    }
	return nil;
}

-(NSArray*)translateContentsOfURL:(NSURL*)url error:(NSError**)error;
{
    NSXMLParser* parser = [[[NSXMLParser alloc] initWithContentsOfURL:url] autorelease];
    if (parser) {
    	return [self translateWithXMLParser:parser
                                      error:error];
    }
	return nil;
}

-(id)currentObject;
{
	CWXMLTranslatorState* state = [stateStack lastObject];
	return state->currentObject;
}

-(void)replaceCurrentObjectWithObject:(id)object;
{
	CWXMLTranslatorState* state = [stateStack lastObject];
	[state->currentObject autorelease];
    state->currentObject= [object retain];
}

-(void)abortTranslation;
{
    didAbort = YES;
    [xmlParser abortParsing];
}

#pragma mark --- Private helpers

-(NSDateFormatter*)dateFormatter;
{
	static NSDateFormatter* formatter = nil;
    if (formatter == nil) {
    	formatter = [[NSDateFormatter alloc] init];
        [formatter setLenient:YES];
    }
    return formatter;
}

-(id)primitiveObjectInstanceOfClass:(Class)aClass withString:(NSString*)aString fromXMLname:(NSString*)name xmlAttributes:(NSDictionary*)attributes toKey:(NSString*)key;
{
    id result = nil;
    BOOL shouldSkip = NO;
    if (_delegateFlags.primitiveObjectInstanceOfClass) {
        NSString* trimmedKey = [key hasPrefix:@"+"] ? [key substringFromIndex:1] : key;
        result = [_delegate xmlTranslator:self
           primitiveObjectInstanceOfClass:aClass
                               withString:aString
                              fromXMLname:name
                            xmlAttributes:attributes
                                    toKey:trimmedKey
                               shouldSkip:&shouldSkip];
    }
    if (result == nil && !shouldSkip) {
        if (aClass == [NSString class]) {
            return aString;
        } else if (aClass == [NSNumber class]) {
            result = [NSDecimalNumber decimalNumberWithString:aString];
        } else if (aClass == [NSDate class]) {
            result = [[CWXMLTranslator defaultDateFormatter] dateFromString:aString];
        } else {
            result = [[[aClass alloc] initWithString:aString] autorelease];
        }
    }
    CWLogInfo(@"Did instantiate primitive object of class %@ for '%@' (expected %@)", 
               NSStringFromClass([result class]), key, NSStringFromClass(aClass));
	return result;
}


-(void)setValue:(id)value forKey:(id)key onObject:(id)target;
{
    if (value) {
        if ([key hasPrefix:@"+"]) {
            key = [key substringFromIndex:1];
            if ([target isKindOfClass:NSClassFromString(@"NSManagedObject")]) {
                [[target mutableSetValueForKey:key] addObject:value];
            } else {
                [[target mutableArrayValueForKey:key] addObject:value];
            }
            CWLogInfo(@"Did add value %@ for '%@'", value, key);
        } else {
            [target setValue:value forKey:key];
            CWLogInfo(@"Did set value %@ for '%@'", value, key);
        }
    }
}


-(id)objectInstanceOfClass:(Class)aClass fromXMLname:(NSString*)name xmlAttributes:(NSDictionary*)attributes toKey:(NSString*)key;
{
    id result = nil;
    BOOL shouldSkip = NO;
    if (_delegateFlags.objectInstanceOfClass) {
        NSString* trimmedKey = [key hasPrefix:@"+"] ? [key substringFromIndex:1] : key;
        result = [_delegate xmlTranslator:self
                    objectInstanceOfClass:aClass
                              fromXMLname:name
                            xmlAttributes:attributes
                                    toKey:trimmedKey
                               shouldSkip:&shouldSkip];
    }
    if (result == nil && !shouldSkip) {
        result = [[[aClass alloc] init] autorelease];
    }
    CWLogInfo(@"Did instantiate object of class %@ for '%@' (expected %@)", 
               NSStringFromClass([result class]), key, NSStringFromClass(aClass));
    return result;
}

#pragma mark --- NSXMLParserDelegate comformance

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict;
{
    CWXMLTranslatorState* state = [stateStack lastObject];
    NSDictionary* currentTranslationPlist = ((CWXMLTranslatorState*)[stateStack lastObject])->translationPlist;
    for (NSString* key in currentTranslationPlist) {
        if ([key isEqualToString:elementName]) {
            CWLogInfo(@"Will handle tag key: %@", key);
            id target = [currentTranslationPlist objectForKey:key];
			if ([target isKindOfClass:[NSDictionary class]]) {
                id currentObject = nil;
                if (![[target objectForKey:@"@dummy"] boolValue]) {
                    Class aClass = NSClassFromString([target objectForKey:@"@class"]);
                    currentObject = [self objectInstanceOfClass:aClass
                                                    fromXMLname:elementName
                                                  xmlAttributes:attributeDict
                                                          toKey:key];
                    if (currentObject) {
                        for (NSString* attrKey in target) {
                        	if ([attrKey hasPrefix:@"."]) {
                                CWLogInfo(@"Will handle attribute key: %@", attrKey);
                                NSString* value = [attributeDict objectForKey:[attrKey substringFromIndex:1]];
                                id key = [target objectForKey:attrKey];
                                if ([key isKindOfClass:[NSArray class]]) {
                                    aClass = NSClassFromString([key objectAtIndex:1]);
                                    key = [key objectAtIndex:0];
                                } else {
                                	aClass = [NSString class];
                                }
                                value = [self primitiveObjectInstanceOfClass:aClass
                                                                  withString:value
                                                                 fromXMLname:[attrKey substringFromIndex:1]
                                                               xmlAttributes:nil
                                                                       toKey:key];
                                [self setValue:value forKey:key onObject:currentObject];
                            }
                        }                        
                    } else {
                    	target = nil;
                    }
                }
                CWXMLTranslatorState* state = [[CWXMLTranslatorState alloc] initWithObject:currentObject];
                state->elementName = [elementName copy];
                state->attributes = [attributeDict copy];
                state->translationPlist = target;
                [stateStack addObject:state];
                [state release];
            } else if ([target isKindOfClass:[NSArray class]]) {
                currentText = [[NSMutableString alloc] init];
                CWXMLTranslatorState* state = [[CWXMLTranslatorState alloc] initWithObject:nil];
                state->elementName = [elementName copy];
                state->attributes = [attributeDict copy];
                state->translationPlist = target;
                [stateStack addObject:state];
                [state release];
            } else if ([target isEqual:@"@object"]) {
                currentText = [[NSMutableString alloc] init];
                CWXMLTranslatorState* state = [[CWXMLTranslatorState alloc] initWithObject:currentText];
                state->elementName = [elementName copy];
                state->attributes = [attributeDict copy];
                state->translationPlist = nil;
                [stateStack addObject:state];
                [state release];
            } else {
                if ([state->elementName isEqualToString:elementName]) {
                    state->nestingCount++;
                }
                currentText = [[NSMutableString alloc] init];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
{
	[currentText appendString:string];
}

-(id)didTranslateObject:(id)anObject fromXMLName:(NSString*)name toKey:(NSString*)key ontoObject:(id)parentObject;
{
    if (_delegateFlags.didTranslateObject) {
        NSString* trimmedKey = [key hasPrefix:@"+"] ? [key substringFromIndex:1] : key;
        anObject = [_delegate xmlTranslator:self
                         didTranslateObject:anObject 
                                fromXMLName:name 
                                      toKey:trimmedKey
                                 ontoObject:parentObject];
    }
	return anObject;
}

- (void)parserDidEndElement:(NSString*)elementName withTypedState:(CWXMLTranslatorState*)state;
{
    NSString* key = nil;
    id currentObject = state->currentObject;
    BOOL isPrimitive = NO;
    if ([state->translationPlist isKindOfClass:[NSDictionary class]]) {
        key = [state->translationPlist objectForKey:@"@key"];
    } else  if ([state->translationPlist isKindOfClass:[NSArray class]]) {
        isPrimitive = YES;
        key = [(id)state->translationPlist objectAtIndex:0];
        if ([key isEqualToString:@"@object"]) {
            key = nil;
        }
        Class aClass = NSClassFromString([(id)state->translationPlist objectAtIndex:1]);
        currentObject = [self primitiveObjectInstanceOfClass:aClass
                                                  withString:currentText
                                                 fromXMLname:elementName
                                               xmlAttributes:state->attributes
                                                       toKey:key];
    }
    if (key) {
        CWXMLTranslatorState* prevState = nil;
        for (int i = 2; YES; i++) {
            prevState = [stateStack objectAtIndex:[stateStack count] - i];
            if (prevState->currentObject) {
                break;
            }
        }
        if (!isPrimitive) {
            currentObject = [self didTranslateObject:currentObject
                                         fromXMLName:elementName
                                              toKey:key
                                          ontoObject:prevState->currentObject];
        }
        if (currentObject) {
            [self setValue:currentObject
                    forKey:key
                  onObject:prevState->currentObject];
        }
    } else if (currentObject) {
        if (!isPrimitive) {
            currentObject = [self didTranslateObject:currentObject
                                         fromXMLName:elementName
                                              toKey:nil
                                          ontoObject:nil];
        }
        if (currentObject) {
            [rootObjects addObject:currentObject];
            CWLogInfo(@"Did add root object %@ for '%@'", object, elementName);
        }
    }
    [stateStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
{
	CWXMLTranslatorState* state = [stateStack lastObject];
    if ([state->elementName isEqualToString:elementName]) {
        if (state->nestingCount > 0) {
            state->nestingCount--;
        } else {
            [self parserDidEndElement:elementName withTypedState:state];
        }
    } else {
        for (NSString* tag in state->translationPlist) {
            if ([tag isEqualToString:elementName]) {
                id key = [state->translationPlist objectForKey:tag];
                if ([key isEqualToString:@"@object"]) {
                    key = nil;
                }
                id value = [self primitiveObjectInstanceOfClass:[NSString class]
                                                     withString:currentText
                                                    fromXMLname:elementName
                                                  xmlAttributes:state->attributes
                                                          toKey:key];
                if (value) {
                    if (key) {
	                	[self setValue:value forKey:key onObject:state->currentObject];
                    } else {
                    	[rootObjects addObject:value];
                    }
                }
            }
        }
    }
    [currentText release];
    currentText = nil;
}

@end
