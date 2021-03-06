//
//  XMLParser.m
//  TaiPing
//
//  Created by bbdtek on 11-11-25.
//  Copyright 2011 bbdtek. All rights reserved.
//

#import "XMLParser.h"
#import "GDataXMLNode.h"
#import "LoginRequest.h"
#import "XmlResponse.h"
//#import "AppDelegate.h"

@interface XMLParser (Private)
//Encode
- (NSString *)doObjEncode:(id)object;
- (NSString *)doEncode:(id)object;

//Decode
- (NSArray *)doDecodeListXML:(NSString *)xml name:(NSString *)listName  path:(NSString *)path;
- (NSArray *)doDecodeXML:(NSString *)xml type:(Class)type path:(NSString *)path;
@end

static XMLParser *xmlparser = nil;
@implementation XMLParser

+ (XMLParser *)sharedInstance {
    if (!xmlparser) {
        xmlparser = [[XMLParser alloc] init];
    }
    return xmlparser;
}

- (NSString *)doEncode:(id)object {
    NSMutableString *resString = [[[NSMutableString alloc] init] autorelease];
    
    [resString appendFormat:@"<%@>", NSStringFromClass([object class])];
    
    NSDictionary *topDictionary = [object properties_aps];
    
    for(NSString *name in topDictionary) {
        NSString *type = [topDictionary objectForKey:name];
        NSRange range =[type rangeOfString:@"Array"];
        
        if(range.location != NSNotFound) {
            NSArray *tmpArray = [object valueForKey:name];
            
            if (tmpArray != nil && [tmpArray count] > 0) {
                [resString appendFormat:@"<%@>",name];
                
                for (id obj in tmpArray) {
                    [resString appendString:[self doEncode:obj]];
                }
                [resString appendFormat:@"</%@>",name];
            }
        }else {
            range =[type rangeOfString:@"NSString"];
            
            if (range.location != NSNotFound) {
                id propertyValue = [object valueForKey:name]; 
                if(propertyValue){
                    [resString appendFormat:@"<%@>%@</%@>", name, propertyValue, name];
                }
            }else {
                id obj = [object valueForKey:name];
                
                NSString *tmpXml = [self doObjEncode:obj];
                if (tmpXml != nil) {
                    [resString appendFormat:@"<%@>",name];
                    [resString appendString:tmpXml];
                    [resString appendFormat:@"</%@>",name];
                }
            }
        }
    }
    
    [resString appendFormat:@"</%@>", NSStringFromClass([object class])];
    
    return  resString;
}


- (NSString *)doObjEncode:(id)object {
    NSMutableString *resString = [[[NSMutableString alloc] init] autorelease];
    
    NSDictionary *topDictionary = [object properties_aps];
    
    for(NSString *name in topDictionary) {
        NSString *type = [topDictionary objectForKey:name];
        NSRange range =[type rangeOfString:@"Array"];
        
        if(range.location != NSNotFound) {
            NSArray *tmpArray = [object valueForKey:name];
            
            if (tmpArray != nil && [tmpArray count] > 0) {
                [resString appendFormat:@"<%@>",name];
                
                for (id obj in tmpArray) {
                    [resString appendString:[self doEncode:obj]];
                }
                [resString appendFormat:@"</%@>",name];
            }
        }else {
            range =[type rangeOfString:@"NSString"];
            
            if (range.location != NSNotFound) {
                id propertyValue = [object valueForKey:name]; 
                if(propertyValue){
                    [resString appendFormat:@"<%@>%@</%@>", name, propertyValue, name];
                }
            }else {
                id obj = [object valueForKey:name];
                
                NSString *tmpXml = [self doObjEncode:obj];
                if (tmpXml != nil) {
                    [resString appendFormat:@"<%@>",name];
                    [resString appendString:tmpXml];
                    [resString appendFormat:@"</%@>",name];
                }
            }
        }
    }
        
    return  resString;
}

- (NSString *)encodeXML:(id)object {
    NSMutableString *xml = [NSMutableString string];
    
    [xml appendString:XML_HEADER];
    [xml appendString:[self doEncode:object]];
    
    return xml;
}
//有问题
- (NSArray *)doDecodeListXML:(NSString *)xml name:(NSString *)listName path:(NSString *)path {    
    NSArray *array = nil;
    
    NSInteger from, to;
    NSString *tmpXml, *classString, *listNameString;
    
    // get class
    listNameString = [NSString stringWithFormat:@"<%@>", listName];
    
    from = ([xml rangeOfString:listNameString].location + listNameString.length);
    
    tmpXml = [xml substringFromIndex:from];
    
    from = ([tmpXml rangeOfString:@"<"].location + @"<".length);
    to = [tmpXml rangeOfString:@">"].location;
    classString = [tmpXml substringWithRange:NSMakeRange(from, (to - from))];
    
    // load XML string
    GDataXMLDocument *gxml = [[GDataXMLDocument alloc] initWithXMLString:xml options:0 error:nil];
    
    // decode
    NSArray *members = [gxml.rootElement nodesForXPath:path error:nil];
    
    for (GDataXMLElement *member in members) {
        NSArray *tmpArray = [self doDecodeXML:xml type:NSClassFromString(classString) path:[NSString stringWithFormat:@"%@/%@", path, classString]];
        array = [NSArray arrayWithArray:tmpArray];
    }
    
    [gxml release];
    
    return array;
}

- (NSArray *)doDecodeXML:(NSString *)xml type:(Class)type path:(NSString *)path {
    NSMutableArray *array = [NSMutableArray array];
    
    NSDictionary *topDictionary = [type properties_aps];
    
    // load XML string
    GDataXMLDocument *gxml = [[GDataXMLDocument alloc] initWithXMLString:xml options:0 error:nil];
    
    // decode
    NSArray *members = [gxml.rootElement nodesForXPath:path error:nil];
    
    for (GDataXMLElement *member in members) {
        id object = [[type alloc] init];
        
        for (NSString *key in [topDictionary allKeys]) {
            NSString *type = [topDictionary objectForKey:key];

            NSArray *names = [member elementsForName:key];
            if (names != nil && [names count] > 0) {
                NSRange range =[type rangeOfString:@"Array"];
                if (range.location != NSNotFound) {
                    GDataXMLElement *firstName = (GDataXMLElement *)[names objectAtIndex:0];
                    if (firstName != nil) {
                        NSArray *sarray = [self doDecodeListXML:firstName.XMLString name:firstName.name path:[NSString stringWithFormat:@"//%@", firstName.name]];
                        
                        [object setValue:sarray forKey:key];
                    }
                }else {
                    range =[type rangeOfString:@"NSString"];
                    
                    if (range.location != NSNotFound) {
                        GDataXMLElement *firstName = (GDataXMLElement *)[names objectAtIndex:0];
                        
                        NSInteger from, to;
                        NSString *dstType;
                        from = [type rangeOfString:@"@\""].location + @"@\"".length;
                        to = [type rangeOfString:@"\","].location;
                        dstType = [type substringWithRange:NSMakeRange(from, (to - from))];
                        
                        GDataXMLElement *firstName = (GDataXMLElement *)[names objectAtIndex:0];
                        NSArray *sarray = [self doDecodeXML:firstName.XMLString type:NSClassFromString(dstType) path:[NSString stringWithFormat:@"//%@", key]];
                        
                        if (sarray != nil && [sarray count] > 0) {
                            id tmpObject = [sarray objectAtIndex:0]; //只有1个对象
                            [object setValue:tmpObject forKey:key];
                        }
                    }
                }
            }
        }
        
        [array addObject:object];
        [object release];
    }
    
    [gxml release];
    
    return array;
}

- (NSArray *)decodeXML:(NSString *)xml {
    NSArray *array = nil;
    NSUInteger offset = [xml rangeOfString:XML_HEADER].location;
	if (offset != NSNotFound) {
		NSString *dstXml = [xml substringFromIndex:(offset + XML_HEADER.length)];
        
        //容错机制－只取一个对象
        offset = [dstXml rangeOfString:XML_HEADER].location;
        if (offset != NSNotFound) {
            dstXml = [dstXml substringToIndex:offset];
        }
        
        NSInteger from = ([dstXml rangeOfString:@"<"].location + 1);
        NSInteger to = [dstXml rangeOfString:@">"].location;
        
        @try {
            NSString *classString = [dstXml substringWithRange:NSMakeRange(from, (to - from))];
            
            @try {
                array = [self doDecodeXML:dstXml type:NSClassFromString(classString) path:[NSString stringWithFormat:@"//%@", classString]];
            }
            @catch (NSException *exception) {
                DLog(@"Decode XML:%@,%@", exception.name, exception.reason);
            }
        }
        @catch (NSException *exception) {
            DLog(@"Get class:%@,%@", exception.name, exception.reason);
        }
    }
    
    return array;
}

@end
