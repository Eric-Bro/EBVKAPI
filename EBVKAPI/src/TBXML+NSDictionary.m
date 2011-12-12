//
//  EBXMLConverter.m
//  

#import "TBXML+NSDictionary.h"

@implementation TBXML (NSDictionaryRepresentation)

+ (id)convertTBXMLElement:(TBXMLElement *)element
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue: [TBXML elementName:element] forKey: @"name"];
    if ([TBXML textForElement: element]) {
        [dictionary setValue: [TBXML textForElement: element] forKey: @"value"];
    }
    /* Travers attributes */
    NSMutableArray *attributes = [NSMutableArray array];
    TBXMLAttribute *attr = element->firstAttribute;
    while (attr) {
        [attributes addObject: [NSDictionary dictionaryWithObjectsAndKeys: [TBXML attributeName:attr], @"name",
                                [TBXML attributeValue: attr], @"value", nil]];
        attr = attr->next;
    }
    if ([attributes count]) {
        [dictionary setValue: attributes
                      forKey: @"attributes"];        
    }

    
    if (!element->firstChild) {
        return dictionary;
    }
    
    TBXMLElement *child = element->firstChild;
    NSMutableArray *children = [NSMutableArray array];
    while (child) {
        [children addObject: [self convertTBXMLElement: child]];
        child = child->nextSibling;
    }
    if ([children count]) {
        [dictionary setValue: children
                      forKey: @"children"]; 
    }
    
    return dictionary;    
}


- (id)dictionaryRepresentation
{
    return [TBXML convertTBXMLElement: self.rootXMLElement];
}


@end
