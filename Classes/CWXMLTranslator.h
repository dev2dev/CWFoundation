//
//  CWXMLTranslator.h
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

#import <Foundation/Foundation.h>


@protocol CWXMLTranslatorDelegate;

/*!
 * @abstract A utility class for traslating a XML document into an object graph.
 *
 * @discussion The translation to apply is defined in a property list. Objects to create must be KVC-complient for the
 *             properties to translate. The root objects will be sent to the delegate, and all other objects int he graph
 *             will be set as properties on their parent.
 *             Translation is a blocking call, and should be called from a background thread.
 *             PLIST FORMAT IS NOT DOCUMENTED AND CAN/WILL CHANGE.
 *
 *			   Core Data support should be implemented by using the thread local managed object 
 *			   context fron the CWCoreData dependency.
 */
@interface CWXMLTranslator : NSObject
/*
#if __IPHONE_4_0 <= __IPHONE_OS_VERSION_MAX_ALLOWED
<NSXMLParserDelegate>
#endif 
*/
{
@private
	id<CWXMLTranslatorDelegate> _delegate;
    struct {
    	unsigned int objectInstanceOfClass:1;
    	unsigned int didTranslateObject:1;
    	unsigned int primitiveObjectInstanceOfClass:1;
    } _delegateFlags;
// Super private!
	NSDictionary* translationPlist;
	NSMutableArray* stateStack;
	NSMutableString* currentText;
	NSMutableArray* rootObjects;
	NSXMLParser* xmlParser;
	BOOL didAbort;
}

/*!
 * @abstract The translation delegate.
 * @discussion The delegate methods are always called on the same thread that the translation was started from.
 */
@property(nonatomic, assign) id<CWXMLTranslatorDelegate> delegate;

/*!
 * @abstract The default NSDateFormatter
 * @discussion Used when translating strings to NSDate.
 */
+ (NSDateFormatter*) defaultDateFormatter;
+ (void) setDefaultDateFormatter:(NSDateFormatter *)formatter;

/*!
 * @abstract Convinience method for translating XML with a translation and delagate.
 * @throws NSInvalidArgumentException if translation could not be found or is invalid.
 */
+(NSArray*)translateContentsOfData:(NSData*)data withTranslationNamed:(NSString*)translation delegate:(id<CWXMLTranslatorDelegate>)delegate error:(NSError**)error;

/*!
 * @abstract Convinience method for translating XML with a translation and delagate.
 * @throws NSInvalidArgumentException if translation could not be found or is invalid.
 */
+(NSArray*)translateContentsOfURL:(NSURL*)url withTranslationNamed:(NSString*)translation delegate:(id<CWXMLTranslatorDelegate>)delegate error:(NSError**)error;

/*!
 * @abstract Init translator with delegate to send created root objects to.
 */
-(id)initWithTranslation:(NSDictionary*)translation delegate:(id<CWXMLTranslatorDelegate>)delegate;

/*!
 * @abstract Translate the XML document in data using a delegate and an optional out error argument.
 */
-(NSArray*)translateContentsOfData:(NSData*)data error:(NSError**)error;

/*!
 * @abstract Translate the XML document referenced by an URL using a default delegate and an optional out error argument.
 */
-(NSArray*)translateContentsOfURL:(NSURL*)url error:(NSError**)error;

/*!
 * @abstract fetch the currently parsed object.
 */
-(id)currentObject;

/*!
 * @abstract Replace the currently parsed object with another object.
 *
 * @discussion Replace with nil to cancel the parsing on the current object.
 */
-(void)replaceCurrentObjectWithObject:(id)object;

/*!
 * @abstract Abort the translation, should be called on the translator from a delegate callback method. 
 */
-(void)abortTranslation;

@end


/*!
 * @abstract Delegate for handling he result of a XML transltion.
 */
@protocol CWXMLTranslatorDelegate <NSObject>

@optional

/*!
 * @abstract Implement for custom instantiation of an object of a given class.
 *
 * @discussion Return an autoreleased and initialized object if you need a custom object initialization.
 *             Otherwise return nil, to let the translator instantiate using [[aClass alloc] init].
 *
 * @param translator the XML translator
 * @param aClass the proposed class to instantiate.
 * @param name the XML element name.
 * @param attributes the XML attributes for the XML element.
 * @param key the key to later set the result to, or nil if a root object.
 * @param skip an out parameter, set to YES if this translation should be skipped for any reason.
 * @result an object instantiated usingt he arguments, or nil if a default object should be instantiated.
 */
-(id)xmlTranslator:(CWXMLTranslator*)translator objectInstanceOfClass:(Class)aClass fromXMLname:(NSString*)name xmlAttributes:(NSDictionary*)attributes toKey:(NSString*)key shouldSkip:(BOOL*)skip;

/*!
 * @abstract Translator did translate an obejct for a specified key.
 *
 * @discussion Called before assigning to the target. Delegate may replace the object, or return nil if the object
 *             should not be set to it's parent ot be added to the root object array.
 */
-(id)xmlTranslator:(CWXMLTranslator*)translator didTranslateObject:(id)anObject fromXMLName:(NSString*)name toKey:(NSString*)key ontoObject:(id)parentObject;

/*!
 * @abstract Implement custom instansiation of a value object of a given class.
 *
 * @discussion Return an autoreleased and initialized object if you need a custom object initialization.
 *             Otherwise return nil, to let the translator instantiate using [[aClass alloc] init].
 *
 * @param translator the XML translator
 * @param aClass the proposed class to instantiate.
 * @param name the XML element or attribute name.
 * @param attributes the XML attributes for the XML element, or nil if instantiating from an attribute.
 * @param key the key to later set the result to, or nil if a root object.
 * @param skip an out parameter, set to YES if this translation should be skipped for any reason.
 * @result an object instantiated usingt he arguments, or nil if a default object should be instantiated.
 */
-(id)xmlTranslator:(CWXMLTranslator*)translator primitiveObjectInstanceOfClass:(Class)aClass withString:(NSString*)aString fromXMLname:(NSString*)name xmlAttributes:(NSDictionary*)attributes toKey:(NSString*)key shouldSkip:(BOOL*)skip;


@end

