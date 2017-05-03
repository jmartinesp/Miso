//
//  ParseSettings.swift
//  SwiftySoup
//
//  Created by Jorge Martín Espinosa on 10/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

public struct ParseSettings {
    
    public static var htmlDefault: ParseSettings { return ParseSettings(preserveTagsCase: false, preserveAttributesCase: false) }
    public static var preserveCase: ParseSettings { return ParseSettings(preserveTagsCase: true, preserveAttributesCase: true) }
    
    public let preserveTagsCase: Bool
    public let preserveAttributesCase: Bool
    
    func normalize(tagName: String) -> String {
        var tagName = tagName
        tagName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return preserveTagsCase ? tagName : tagName.lowercased()
    }
    
    func normalize(attributeName: String) -> String {
        var attributeName = attributeName
        attributeName = attributeName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return preserveAttributesCase ? attributeName : attributeName.lowercased()
    }
    
    func normalize(attributes: Attributes) -> Attributes {
        var newAttributes = Attributes()
        if !preserveAttributesCase {
            attributes.orderedKeys.forEach {
                let oldAttribute = attributes[$0]!
                if oldAttribute is BooleanAttribute {
                    newAttributes[$0.lowercased()] = BooleanAttribute(tag: oldAttribute.tag.lowercased())
                } else {
                    newAttributes[$0.lowercased()] = Attribute(tag: oldAttribute.tag.lowercased(), value: oldAttribute.value)
                }
            }
        } else {
            newAttributes = attributes
        }
        return newAttributes
    }
}
